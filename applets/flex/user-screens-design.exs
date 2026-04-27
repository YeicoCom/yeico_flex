use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Screen Designer" label={@screen.name}>
    <div id="design_frame" class="relative h-full w-full" phx-hook="DesignFrame">
      <div id="design_port" :if={@vp.frame} class="design-port absolute overflow-hidden">
        <div id="design_grid" class="design-panel absolute origin-top-left"/>
        <div id="design_rulerx" class="design-panel absolute origin-top-left text-zinc-500" style="top: 0em;">
          <div :for={p <- 10..90//10} class="absolute text-[6px] top-[-8px]" style={"left: #{p}%;"}>{p}%</div>
        </div>
        <div id="design_rulery" class="design-panel absolute origin-top-left text-zinc-500" style="left: 0em;">
          <div :for={p <- 10..90//10} class="absolute text-[6px] left-[1px]" style={"top: #{p}%;"}>{p}%</div>
        </div>
        <div id="design_panel" class="design-panel absolute origin-top-left" draggable="false">
          <.fui :for={item <- @screen.items} fun={@sd.item}
            x={item.x} y={item.y} w={item.w} h={item.h} bg={item.bg}/>
        </div>
      </div>
      <.fui id="design_menu" :if={@menu} fun={@sd.menu} x={@menu.x} y={@menu.y}/>
    </div>
      <style :if={@vp.frame}>
        /* https://www.magicpattern.design/tools/css-backgrounds */
        #design_grid {
          background-image: linear-gradient(#444444 2px, transparent 2px), linear-gradient(90deg, #444444 2px, transparent 2px), linear-gradient(#444444 1px, transparent 1px), linear-gradient(90deg, #444444 1px, transparent 1px);
          background-size: 100px 100px, 100px 100px, 10px 10px, 10px 10px;
          background-position: -1px -1px, -1px -1px, -1px -1px, -1px -1px;
        }
        .design-port {
          left: <%= @vp.port.x %>px;
          top: <%= @vp.port.y %>px;
          width: <%= @vp.port.w %>px;
          height: <%= @vp.port.h %>px;
        }
        .design-panel {
          scale: <%= @vp.panel.s %>;
          left: <%= @vp.panel.x %>px;
          top: <%= @vp.panel.y %>px;
          width: <%= @vp.panel.w %>px;
          height: <%= @vp.panel.h %>px;
        }
      </style>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Screen Designer")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :screen, %{})
    state = Map.put(state, :menu, nil)
    state = Map.put(state, :vp, nil)
    state = Map.put(state, :sd, sd)
    state = Map.put(state, :ui, ui)
    {socket, sd.apply.(state, :init, nil)}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    screen = Api.subget!("flex:user-screens:item:#{id}")
    state = put_in(state, [:screen, :name], screen[:name])
    state = put_in(state, [:screen, :id], id)
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "cmd:fit", params = %{"fit" => fit}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, sd.apply.(state, :fit, fit)}

  {:event, socket, state, event = "cmd:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "frame:click", params = %{"x" => x, "y" => y}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, %{x: x, y: y})
    {socket, state}

  {:event, socket, state, event = "frame:wheel",
   params = %{"x" => x, "y" => y, "dx" => dx, "dy" => dy}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, sd.apply.(state, :wheel, {x, y, dx, dy})}

  {:event, socket, state, event = "frame:drag",
   params = %{"mx" => mx, "my" => my, "ox" => ox, "oy" => oy, "e" => e, "m" => m}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, sd.apply.(state, :drag, {mx, my, ox, oy, e, m})}

  {:event, socket, state, event = "frame:resize", params = %{"width" => w, "height" => h}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, sd.apply.(state, :resize, {w, h})}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, screen}} ->
    Api.trace(view: path, info: event)
    state = put_in(state, [:screen, :name], screen[:name])
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
