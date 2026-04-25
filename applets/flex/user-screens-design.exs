use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Screen Designer" label={@screen.name}>
    <div id="design_frame" class="relative h-full w-full bg-zinc-800 rounded" phx-hook="DesignFrame">
      <div id="design_port" :if={@vp.port} class="absolute bg-zinc-900"
        style={[
          "left: #{@vp.port.x}px; top: #{@vp.port.y}px;",
          "width: #{@vp.port.w}px;height: #{@vp.port.h}px;",
        ]}>
        <div id="design_panel" :if={@vp.panel} class="absolute bg-zinc-700"
          style={[
            "transform-origin: 0 0;scale: #{@vp.panel.s};",
            "left: #{@vp.panel.x}px; top: #{@vp.panel.y}px;",
            "width: #{@vp.panel.w}px;height: #{@vp.panel.h}px;"
          ]}>
          <.fui :for={item <- @screen.items} fun={@sd.item} x={item.x} y={item.y} w={item.w} h={item.h}/>
        </div>
      </div>
      <.fui id="frame_menu" :if={@menu} fun={@sd.menu} x={@menu.x} y={@menu.y}/>
    </div>
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
