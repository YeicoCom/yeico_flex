defmodule Flex.UserScreens.Design do
  alias Flex.UserScreens.DUtils
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Screen Designer" label={@name} class="flex gap-2">
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
            <.fui :for={{id, item} <- @index} fun={&DUtils.item/1} id={id} {item} rt={@rts[id]}
              selected={id==@selected.id} rt?={@rt?} grid={@screen.props.grid}/>
          </div>
        </div>
        <.fui id="design_menu" :if={@menu} fun={&DUtils.menu/1} x={@menu.x} y={@menu.y} items={@menu.items?}
          phx-click-away="modal:close"/>
      </div>
      <div class="flex flex-col p-1 gap-2 w-[16em] overflow-y-auto">
        <div class="text-xl flex items-center">
          <div>{@selected.type} Properties</div>
          <div class="grow"/>
          <div :if={@selected.id} phx-click="item:clone" phx-value-id={@selected.id} class="hero-document-duplicate" title="Clone"/>
        </div>
        <.fui id="props_editor" fun={&DUtils.form/1} selected={@selected} rt={@rts[@selected.id]}
          phx-submit="item:change" phx-change="item:change" phx-value-id={@selected.id || 0}
          class="[&_*]:text-xs grid grid-cols-[auto_1fr] gap-y-1 gap-x-2 items-center"/>
        <div class="grow"/>
        <.fui fun={&UI.link/1} :if={@selected.id} type="danger" class="text-xs justify-end"
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

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    ddb = Keyword.fetch!(opts, :ddb)

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Screen Designer")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :events, %{})
        state = Map.put(state, :menu, nil)
        state = Map.put(state, :name, nil)
        state = Map.put(state, :rt?, false)
        state = Map.put(state, :rts, %{})
        state = Map.put(state, :id, nil)
        state = Ln.init(socket, state)
        {socket, state}

      {:params, socket, state = %{login?: true, user: nil}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        socket = Ln.forward(socket, path, uri)
        {socket, state}

      {:params, socket, state, params = %{"id" => id}, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        state = DUtils.calc_layout(state, :init, DUtils.load_screen(ddb, id))
        state = Map.put(state, :selected, DUtils.select(state, "Screen", nil))
        # it may not exist: use screen[:name] assessor
        screen = Api.subget!("flex:user-screens:item:#{id}")
        state = Map.put(state, :name, screen[:name])
        state = Map.put(state, :id, id)

        state =
          for {id, item} <- state.screen.items, reduce: state do
            state -> DUtils.init(state, id, item, true)
          end

        {socket, state}

      {:render, _assigns, state = %{screen: %{items: items}}} ->
        # indexing on render simplifies the for above
        # doing it just here saves to carry dupplicated items
        # no improvement in id accesing items above
        # dragging requires reindexing to refresh cached items
        index = Enum.sort_by(items, fn {_, item} -> item.index end)
        state = Map.put(state, :index, index)
        view(state)

      {:event, socket, state, event = "modal:close", params} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :menu, nil)
        {socket, state}

      {:event, socket, state = %{selected: %{id: nil, save: save}}, event = "item:change",
       params = %{"id" => "0"}} ->
        Log.trace(view: path, event: event, params: params)
        state = save.(state, nil, params)
        state = Map.put(state, :menu, nil)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state = %{selected: %{id: id, save: save}}, event = "item:change",
       params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = save.(state, id, params)
        state = Map.put(state, :menu, nil)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state = %{selected: %{id: id}}, event = "item:keydown",
       params = %{"id" => id, "key" => "Backspace"}} ->
        Log.trace(view: path, event: event, params: params)
        state = DUtils.remove(state, id)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state = %{selected: %{id: id}}, event = "item:keydown",
       params = %{"id" => id, "key" => "Delete"}} ->
        Log.trace(view: path, event: event, params: params)
        state = DUtils.remove(state, id)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state = %{selected: %{id: id}}, event = "item:delete",
       params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = DUtils.remove(state, id)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state = %{selected: %{id: id, item: item = %{type: type}}},
       event = "item:clone", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        id = UUID.uuid1() |> ShortUUID.encode!()
        item = %{item | index: DUtils.max(state) + 1}
        state = put_in(state, [:screen, :items, id], item)
        state = DUtils.init(state, id, item, true)
        state = Map.put(state, :selected, DUtils.select(state, type, id))
        state = Map.put(state, :menu, nil)
        DUtils.save_screen(ddb, state, false)
        socket = push_event(socket, "item:select", %{id: id, type: type})
        {socket, state}

      {:event, socket,
       state = %{screen: screen, vp: %{port: %{s: s, x: pox, y: poy}, panel: %{x: pax, y: pay}}},
       event = "item:add", params = %{"x" => x, "y" => y, "type" => type}} ->
        Log.trace(view: path, event: event, params: params)
        id = UUID.uuid1() |> ShortUUID.encode!()
        # macos sends integers, linux sends floats
        {x, ""} = Float.parse(x)
        {y, ""} = Float.parse(y)
        x = (x - pox - pax) / s
        y = (y - poy - pay) / s
        {x, y} = DUtils.snap(x, y, screen)
        index = DUtils.max(state) + 1
        props = DUtils.props(type)
        item = %{x: x, y: y, w: 0, h: 0, type: type, props: props, index: index}
        state = put_in(state, [:screen, :items, id], item)
        state = DUtils.init(state, id, item, true)
        state = Map.put(state, :selected, DUtils.select(state, type, id))
        state = Map.put(state, :menu, nil)
        DUtils.save_screen(ddb, state, false)
        socket = push_event(socket, "item:select", %{id: id, type: type})
        {socket, state}

      {:event, socket, state, event = "item:select", params = %{"id" => "item_" <> id_type}} ->
        Log.trace(view: path, event: event, params: params)
        [id, type] = String.split(id_type, "_")
        state = Map.put(state, :selected, DUtils.select(state, type, id))
        state = Map.put(state, :menu, nil)
        {socket, state}

      {:event, socket, state = %{screen: screen}, event = "item:drag",
       params = %{"id" => "item_" <> id_type, "x" => x, "y" => y, "e" => _e, "m" => _m}} ->
        Log.trace(view: path, event: event, params: params)
        [id, type] = String.split(id_type, "_")
        {x, y} = DUtils.snap(x, y, screen)
        state = put_in(state, [:screen, :items, id, :x], x)
        state = put_in(state, [:screen, :items, id, :y], y)
        state = Map.put(state, :selected, DUtils.select(state, type, id))
        state = Map.put(state, :menu, nil)
        DUtils.save_screen(ddb, state, false)
        {socket, state}

      {:event, socket, state, event = "frame:fit", params = %{"fit" => fit}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :menu, nil)
        {socket, DUtils.calc_layout(state, :fit, fit)}

      {:event, socket, state, event = "frame:click", params = %{"x" => x, "y" => y, "p" => p}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :selected, DUtils.select(state, "Screen", nil))
        state = Map.put(state, :menu, %{x: x, y: y, items?: p})
        {socket, state}

      {:event, socket, state, event = "frame:wheel",
       params = %{"x" => x, "y" => y, "dx" => dx, "dy" => dy}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :selected, DUtils.select(state, "Screen", nil))
        state = Map.put(state, :menu, nil)
        {socket, DUtils.calc_layout(state, :wheel, {x, y, dx, dy})}

      {:event, socket, state, event = "frame:drag",
       params = %{"mx" => mx, "my" => my, "ox" => ox, "oy" => oy, "e" => e, "m" => m}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :selected, DUtils.select(state, "Screen", nil))
        state = Map.put(state, :menu, nil)
        {socket, DUtils.calc_layout(state, :drag, {mx, my, ox, oy, e, m})}

      {:event, socket, state, event = "frame:resize", params = %{"width" => w, "height" => h}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :selected, DUtils.select(state, "Screen", nil))
        state = Map.put(state, :menu, nil)
        {socket, DUtils.calc_layout(state, :resize, {w, h})}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, _}} ->
        Log.trace(view: path, info: event)
        socket = push_event(socket, "hook:reload", %{})
        {socket, state}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, reason} ->
        Log.trace(view: path, close: reason)
        :ok
    end
  end
end

:ok
