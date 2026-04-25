use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Screen Designer" label={@screen.name}>
    <div id="design_frame" class="relative h-full w-full bg-zinc-800 rounded" phx-hook="DesignFrame">
      <div id="design_port" :if={@size} class="absolute bg-zinc-900"
        style={"left: #{@view.x}px; top: #{@view.y}px;width: #{@view.width}px;height: #{@view.height}px;"}>
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
    state = Map.put(state, :design, sd.new)
    state = Map.put(state, :size, nil)
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

  {:render, _assigns, state = %{size: size, design: %{fit: fit, port: port}}} ->
    case {size, fit} do
      {nil, _} -> state
      {_, _} -> Map.put(state, :view, sd.fit.(fit, size, port))
    end
    |> view.()

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "cmd:fit", params = %{"fit" => fit}} ->
    Api.trace(view: path, event: event, params: params)
    state = put_in(state, [:design, :fit], fit)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "frame:click", params = %{"x" => x, "y" => y}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, %{x: x, y: y})
    {socket, state}

  {:event, socket, state, event = "frame:resize", params = %{"width" => w, "height" => h}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :size, %{width: w, height: h})
    {socket, state}

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
