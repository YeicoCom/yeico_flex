use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} reverse={true} title="Screen Designer" label={@name} class="flex gap-2">
    <div id="design_frame" class="grow relative" phx-hook="ScreenDesigner">
      <div id="design_port" :if={@vp.frame} class="design-port overflow-hidden">
        <div id="design_style" class="design-panel" style={@screen.props.style}/>
        <div :if={@screen.props.grid} id="design_grid" class="design-panel"/>
        <div :if={@screen.props.grid} id="design_rulerx" class="design-panel text-zinc-500" style="top: 0em;">
          <div :for={p <- 10..90//10} class="absolute text-[6px] top-[-8px]" style={"left: #{p}%;"}>{p}%</div>
        </div>
        <div :if={@screen.props.grid} id="design_rulery" class="design-panel text-zinc-500" style="left: 0em;">
          <div :for={p <- 10..90//10} class="absolute text-[6px] left-[1px]" style={"top: #{p}%;"}>{p}%</div>
        </div>
        <div id="design_panel" class="design-panel text-white select-none text-base [&_*]:cursor-default leading-none" draggable="false">
          <.fui :for={{id, item} <- @index} fun={@dutils.item} id={id} {item} rt={@rts[id]} selected={id==@selected.id} runtime={false}/>
        </div>
      </div>
      <.fui id="design_menu" :if={@menu} fun={@dutils.menu} x={@menu.x} y={@menu.y} items={@menu.items?}
        phx-click-away="modal:close"/>
    </div>
    <div class="flex flex-col p-1 gap-2 w-[16em] overflow-y-auto">
      <div class="text-xl">{@selected.type} Properties</div>
      <.fui id="props_editor" fun={@dutils.form} editor={@selected.editor} iid={@selected.id} item={@selected.item} rt={@rts[@selected.id]}
        phx-submit="item:save" phx-change="item:save" class="[&_*]:text-xs grid grid-cols-[auto_1fr] gap-y-1 gap-x-2 items-center"/>
      <div class="grow"/>
      <.fui fun={@ui.link} :if={@selected.id} type="danger" class="text-xs justify-end"
        phx-click="item:delete" phx-value-id={@selected.id}>Delete</.fui>
    </div>
  </.fui>
  <style :if={@vp.frame}>
    /* https://www.magicpattern.design/tools/css-backgrounds */
    #design_grid {
      background-image: linear-gradient(#444444 2px, transparent 2px), linear-gradient(90deg, #444444 2px, transparent 2px), linear-gradient(#444444 1px, transparent 1px), linear-gradient(90deg, #444444 1px, transparent 1px);
      background-size: 100px 100px, 100px 100px, 10px 10px, 10px 10px;
      background-position: -1px -1px, -1px -1px, -1px -1px, -1px -1px;
    }
    .design-port {
      position: absolute;
      left: <%= @vp.port.x %>px;
      top: <%= @vp.port.y %>px;
      width: <%= @vp.port.w %>px;
      height: <%= @vp.port.h %>px;
    }
    .design-panel {
      position: absolute;
      transform-origin: top left;
      scale: <%= @vp.panel.s %>;
      left: <%= @vp.panel.x %>px;
      top: <%= @vp.panel.y %>px;
      width: <%= @vp.panel.w %>px;
      height: <%= @vp.panel.h %>px;
    }
  </style>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Screen Designer")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :dutils, dutils)
    state = Map.put(state, :events, %{})
    state = Map.put(state, :menu, nil)
    state = Map.put(state, :name, nil)
    state = Map.put(state, :rts, %{})
    state = Map.put(state, :id, nil)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    state = dutils.apply.(state, :init, dutils.load_screen.(id))
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    # it may not exist: use screen[:name] accesor
    screen = Api.subget!("flex:user-screens:item:#{id}")
    state = Map.put(state, :name, screen[:name])
    state = Map.put(state, :id, id)

    state =
      for {id, item} <- state.screen.items, reduce: state do
        state -> dutils.init.(state, id, item, true)
      end

    {socket, state}

  {:render, _assigns, state = %{screen: %{items: items}}} ->
    # indexing on render simplifies the for above
    # doing it just here saves to carry dupplicated items
    # no improvement in id accesing items above
    # dragging requires reindexing to refresh cached items
    index = Enum.sort_by(items, fn {_, item} -> item.index end)
    state = Map.put(state, :index, index)
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state = %{selected: %{id: id, save: save}}, event = "item:save",
   params = %{"iid" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = save.(state, id, params)
    state = Map.put(state, :menu, nil)
    dutils.save_screen.(state)
    {socket, state}

  {:event, socket, state = %{selected: %{id: id}}, event = "item:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    {_, state} = pop_in(state, [:rts, id])
    {_, state} = pop_in(state, [:screen, :items, id])
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    state = Map.put(state, :menu, nil)
    dutils.save_screen.(state)
    {socket, state}

  {:event, socket, state = %{vp: %{port: %{s: s, x: pox, y: poy}, panel: %{x: pax, y: pay}}},
   event = "item:add", params = %{"x" => x, "y" => y, "type" => type}} ->
    Api.trace(view: path, event: event, params: params)
    id = UUID.uuid1() |> ShortUUID.encode!()
    x = String.to_integer(x)
    y = String.to_integer(y)
    x = (x - pox - pax) / s
    y = (y - poy - pay) / s
    index = dutils.max.(state) + 1
    props = dutils.props.(type)
    item = %{x: x, y: y, w: 0, h: 0, type: type, props: props, index: index}
    state = put_in(state, [:screen, :items, id], item)
    state = dutils.init.(state, id, item, true)
    state = Map.put(state, :selected, dutils.select.(state, type, id))
    state = Map.put(state, :menu, nil)
    dutils.save_screen.(state)
    {socket, state}

  {:event, socket, state = %{screen: %{props: %{snap: snap, w: w, h: h}}}, event = "item:drag",
   params = %{"id" => "item_" <> id_type, "x" => x, "y" => y, "e" => _e, "m" => _m}} ->
    Api.trace(view: path, event: event, params: params)
    [id, type] = String.split(id_type, "_")
    x = div(round(x), snap) * snap
    y = div(round(y), snap) * snap
    # w/h optional: one pixel to witness out of bounds controls
    x = min(max(x, 0), w - 1)
    y = min(max(y, 0), h - 1)
    state = put_in(state, [:screen, :items, id, :x], x)
    state = put_in(state, [:screen, :items, id, :y], y)
    state = Map.put(state, :selected, dutils.select.(state, type, id))
    state = Map.put(state, :menu, nil)
    dutils.save_screen.(state)
    {socket, state}

  {:event, socket, state, event = "frame:fit", params = %{"fit" => fit}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, dutils.apply.(state, :fit, fit)}

  {:event, socket, state, event = "frame:click", params = %{"sid" => "item_" <> id_type}} ->
    Api.trace(view: path, event: event, params: params)
    [id, type] = String.split(id_type, "_")
    state = Map.put(state, :selected, dutils.select.(state, type, id))
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "frame:click", params = %{"x" => x, "y" => y, "p" => p}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    state = Map.put(state, :menu, %{x: x, y: y, items?: p})
    {socket, state}

  {:event, socket, state, event = "frame:wheel",
   params = %{"x" => x, "y" => y, "dx" => dx, "dy" => dy}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    state = Map.put(state, :menu, nil)
    {socket, dutils.apply.(state, :wheel, {x, y, dx, dy})}

  {:event, socket, state, event = "frame:drag",
   params = %{"mx" => mx, "my" => my, "ox" => ox, "oy" => oy, "e" => e, "m" => m}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    state = Map.put(state, :menu, nil)
    {socket, dutils.apply.(state, :drag, {mx, my, ox, oy, e, m})}

  {:event, socket, state, event = "frame:resize", params = %{"width" => w, "height" => h}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :selected, dutils.select.(state, "Screen", nil))
    state = Map.put(state, :menu, nil)
    {socket, dutils.apply.(state, :resize, {w, h})}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, screen}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :name, screen[:name])
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

:ok
