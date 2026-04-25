use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Screen Designer" label={@screen.name}>
    <div class="relative h-full w-full" phx-click="click:frame">
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
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, nil)
    {socket, state}

  {:event, socket, state, event = "click:frame", params = %{"offsetX" => ox, "offsetY" => oy}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :menu, %{x: ox, y: oy})
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
