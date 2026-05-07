use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} reverse={true} title="Script Editor" label={@name} class="grid grid-cols-2">
    <div id="script_editor" class="h-full overflow-y-scroll" phx-hook="ScriptEditor" phx-update="ignore"/>
    <div phx-update="stream" id="logs" class="flex flex-col overflow-y-auto text-xs select-text font-mono" phx-hook="AutoScroll">
      <div :for={{id, %{stamp: stamp, level: level, style: style, line: line}} <- @streams.logs}
        id={id} class={style}>{stamp} {level} {line}</div>
    </div>
  </.fui>
  """
end

style = fn
  :error -> "text-red-500"
  :warn -> "text-yellow-500"
  :info -> "text-blue-500"
  :debug -> "text-teal-500"
  :trace -> "text-gray-500"
  :unhandled -> "text-red-700"
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Script Editor")
    socket = assign(socket, page_suffix: " · Flex")
    socket = stream(socket, :logs, [])
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :name, nil)
    state = Map.put(state, :logid, 0)
    state = Map.put(state, :id, nil)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    Applet.subscribe!(:trace, id, nil)
    # it may not exist: use script[:name] assessor
    script = Api.subget!("flex:user-scripts:item:#{id}")
    state = Map.put(state, :name, script[:name])
    state = Map.put(state, :id, id)
    socket = push_event(socket, "hook:init", %{code: iutils.load.(id)})
    {socket, state}

  {:render, assigns, state} ->
    state = Map.put(state, :streams, assigns.streams)
    view.(state)

  {:event, socket, state = %{id: id}, event = "hook:save", params = %{"code" => code}} ->
    Api.trace(view: path, event: event, params: params)
    iutils.save.(id, code, false)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id, logid: logid}, event = {{:logger, id, level}, _, line}} ->
    Api.trace(view: path, info: event)
    line = line |> String.replace_prefix("script ", "")
    stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)
    log = %{id: logid, stamp: stamp, level: level, style: style.(level), line: line}
    socket = stream(socket, :logs, [log])
    state = Map.update!(state, :logid, &(&1 + 1))
    {socket, state}

  # reload only on delete to catch reenable logs
  {:info, socket, state = %{id: id}, event = {"flex:user-scripts:item:" <> id, _, nil}} ->
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
