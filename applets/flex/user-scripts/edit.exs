use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} reverse={true} title="Script Editor" label={@name}>
    <div id="script_editor" class="h-full w-full overflow-y-scroll" phx-hook="ScriptEditor"></div>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Script Editor")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :name, nil)
    state = Map.put(state, :id, nil)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    # it may not exist: use script[:name] assessor
    script = Api.subget!("flex:user-scripts:item:#{id}")
    state = Map.put(state, :name, script[:name])
    state = Map.put(state, :id, id)
    socket = push_event(socket, "hook:init", %{code: iutils.load.(id)})
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state = %{id: id}, event = "hook:save", params = %{"code" => code}} ->
    Api.trace(view: path, event: event, params: params)
    iutils.save.(id, code, false)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-scripts:item:" <> id, _, _}} ->
    Api.trace(view: path, info: event)
    socket = push_event(socket, "hook:reload", %{})
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

:ok
