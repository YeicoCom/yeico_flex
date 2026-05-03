use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Home">
    <div class="flex flex-col gap-4 justify-center items-center overflow-y-auto h-full text-3xl">
      <.fui :for={{id, item} <- @items} fun={@ui.href} href={"/flex/user-screens/viewer?id=#{id}"}>{item.name}</.fui>
    </div>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_suffix: " · Flex")
    socket = assign(socket, page_title: "Home")
    items = Api.subget!("flex:user-screens:items") || []
    items = Enum.filter(items, fn {_, v} -> v.status == :enabled end)
    state = Map.put(state, :ui, libUserInterface)
    state = Map.put(state, :items, items)
    {socket, state}

  {:params, socket, state, params, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:user-screens:items", _, items}} ->
    Api.trace(view: path, info: event)
    items = Enum.filter(items, fn {_, v} -> v.status == :enabled end)
    state = Map.put(state, :items, items)
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
