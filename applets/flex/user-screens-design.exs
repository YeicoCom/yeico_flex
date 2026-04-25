use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Screen Designer" label={@screen.name}>
    <div id="design_frame" class="relative h-full w-full bg-zinc-800 rounded" phx-hook="DesignFrame">
      <div id="design_port" :if={@port} class="absolute bg-zinc-900"
        style={"left: #{@port.x}px; top: #{@port.y}px;width: #{@port.w}px;height: #{@port.h}px;"}>
        <div id="design_panel" class="absolute bg-zinc-700"
          style={[
            "transform-origin: 0 0;scale: #{@panel.s};",
            "left: #{@panel.x}px; top: #{@panel.y}px;",
            "width: #{@panel.w}px;height: #{@panel.h}px;"
          ]}>
          <.fui :for={item <- @design.items} fun={@sd.item} x={item.x} y={item.y} w={item.w} h={item.h}/>
        </div>
      </div>
      <.fui id="frame_menu" :if={@menu} fun={@sd.menu} x={@menu.x} y={@menu.y}/>
    </div>
  </.fui>
  """
end

resize = fn
  state = %{frame: nil} ->
    state

  state = %{frame: frame, design: %{fit: fit, port: port = %{x: x, y: y}, size: size}} ->
    port = %{w: w} = sd.fit.({fit, frame, port})
    state = Map.put(state, :port, port)
    panel = sd.fit.({%{x: x, y: y, w: w}, size})
    state = Map.put(state, :panel, panel)
    Api.warn(port: port, panel: panel)
    state
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Screen Designer")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :design, sd.new)
    state = Map.put(state, :frame, nil)
    state = Map.put(state, :panel, nil)
    state = Map.put(state, :port, nil)
    state = Map.put(state, :menu, nil)
    state = Map.put(state, :sd, sd)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    screen = Api.subget!("flex:user-screens:item:#{id}")
    state = Map.put(state, :screen, screen || lib.new)
    state = Map.put(state, :id, id)
    {socket, state}

  {:render, _assigns, state} ->
    Api.warn(state.design.items)
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "cmd:fit", params = %{"fit" => fit}} ->
    Api.trace(view: path, event: event, params: params)
    state = put_in(state, [:design, :fit], fit)
    state = Map.put(state, :menu, nil)
    {socket, resize.(state)}

  {:event, socket, state = %{design: %{items: items}}, event = "cmd:add", params} ->
    Api.trace(view: path, event: event, params: params)
    item = %{x: 0, y: 100, w: 800, h: 10}
    state = put_in(state, [:design, :items], [item | items])
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "frame:click", params = %{"x" => x, "y" => y}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, %{x: x, y: y})
    {socket, state}

  {:event, socket, state, event = "frame:resize", params = %{"width" => w, "height" => h}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :frame, %{w: w, h: h})
    {socket, resize.(state)}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, screen}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :screen, screen)
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
