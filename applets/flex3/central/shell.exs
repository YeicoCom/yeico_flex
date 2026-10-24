use Terminal.Live

render = fn assigns ->
  ~H"""
  <div id="main_view" class="flex flex-col h-screen w-full gap-4 p-16">
    <div class="flex gap-2 justify-center items-center">
      <div class="text-3xl">Shell</div>
      <div class="grow"/>
      <div :if={@live} class="flex gap-2">
        <div title={@owner}>{@host}</div>
        <div :if={@name}>{@name}</div>
      </div>
      <a href={Flex.Gauth.logout_url()} title={@guser.email} class="daisy-link daisy-link-hover hover:text-warning">Logout</a>
    </div>
    <div phx-update="stream" id="events" phx-hook="Scroll" class="grow flex flex-col overflow-y-auto whitespace-pre font-mono">
      <div :for={{id, %{style: style, text: text}} <- @streams.events}
        id={id} class={style}>{text}</div>
    </div>
    <form class="grid grid-cols-1 gap-2" phx-change="input:change" phx-submit="input:run">
      <input id="cmd" phx-hook="History" name="cmd" type="text" autocomplete="off" title="Press Enter to Run"
        class="grow daisy-input daisy-input-bordered"
        value={@input[:cmd]}/>
      <button type="submit" class="hidden">Run</button>
    </form>
  </div>
  """
end

style = fn
  :error -> "text-error"
  :output -> "text-info"
  :input -> "text-accent"
end

handler = fn
  {:mount, socket = %{assigns: assigns}, state} ->
    applet = props[:applet_name] || "flex3"
    socket = assign(socket, applet_css: props[:applet_css] || "/applets/#{applet}.css")
    socket = assign(socket, applet_js: props[:applet_js] || "/applets/#{applet}.js")
    socket = assign(socket, page_suffix: props[:page_suffix] || " · Flex")
    socket = assign(socket, page_title: props[:page_title] || "Shell")
    socket = assign(socket, applet_args: props[:applet_args])
    socket = stream(socket, :events, [])
    state = Map.put(state, :connected?, assigns.connected?)
    state = Map.put(state, :tzoffset, assigns.tzoffset)
    state = Map.put(state, :host, assigns.params["host"])
    state = Map.put(state, :guser, assigns.session["guser"])
    state = Map.put(state, :live, false)
    state = Map.put(state, :input, %{})
    state = Map.put(state, :owner, nil)
    state = Map.put(state, :name, nil)
    state = Map.put(state, :id, 0)
    {socket, state}

  {:render, assigns, state} ->
    state = Map.put(state, :streams, assigns.streams)
    render.(state)

  {:params, socket, state = %{connected?: connected?, host: host}, params, uri} ->
    Log.trace(params: path, params: params, uri: uri)
    if connected?, do: Terminal.Publish.subscribe!({:slave, :host, host})

    case Terminal.Unique.lookup({:slave, host}) do
      [{_, %{owner: owner, name: name}}] ->
        {socket, Map.merge(state, %{owner: owner, name: name, live: true})}

      _ ->
        {socket, Map.merge(state, %{owner: nil, name: nil, live: false})}
    end

  {:event, socket, state, "input:change", params = %{"_target" => [target]}} ->
    state = put_in(state, [:input, String.to_atom(target)], params[target])
    {socket, state}

  {:event, socket, state = %{id: id, host: host, guser: %{email: owner}, owner: owner},
   "input:run", %{"cmd" => cmd}} ->
    stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)
    event = %{id: id, style: style.(:input), text: "#{stamp} #{cmd}"}
    socket = stream(socket, :events, [event])
    state = Map.update!(state, :id, &(&1 + 1))
    state = put_in(state, [:input, :cmd], "")
    cmd = %{shell: true, script: cmd}
    Api.async(fn -> Terminal.run(host, cmd) end)
    {socket, state}

  {:event, socket, state = %{id: id, host: host, guser: %{email: ^admin}, owner: nil},
   "input:run", %{"cmd" => cmd}} ->
    stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)
    event = %{id: id, style: style.(:input), text: "#{stamp} #{cmd}"}
    socket = stream(socket, :events, [event])
    state = Map.update!(state, :id, &(&1 + 1))
    state = put_in(state, [:input, :cmd], "")
    cmd = %{shell: true, script: cmd}
    Api.async(fn -> Terminal.run(host, cmd) end)
    {socket, state}

  {:event, socket, state, event, params} ->
    Log.trace(event: path, event: event, params: params)
    {socket, state}

  # test with
  # :os.cmd('find /root')
  # :os.cmd('find ~/.terminal')
  # :os.cmd('find ~/.terminal') |> to_string()
  # multiline strings get auto split by the pre tag, multiline charlists do not
  # [] should print as []
  {:info, socket, state = %{id: id}, {_ref, {:ok, {:ok, res}}}} ->
    stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)

    text =
      cond do
        is_binary(res) -> res
        is_list(res) and length(res) > 0 and List.ascii_printable?(res) -> to_string(res)
        true -> inspect(res, pretty: true, limit: :infinity)
      end

    events = [
      %{id: id, style: style.(:output), text: "#{stamp}"},
      %{id: id + 1, style: style.(:output), text: text}
    ]

    socket = stream(socket, :events, events)
    state = Map.update!(state, :id, &(&1 + 2))
    {socket, state}

  # test with
  # raise "RAISED"
  {:info, socket, state = %{id: id}, {_ref, {:ok, {:error, error}}}} ->
    stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)

    events = [
      %{id: id, style: style.(:error), text: "#{stamp}"},
      %{id: id + 1, style: style.(:error), text: inspect(error, pretty: true, limit: :infinity)}
    ]

    socket = stream(socket, :events, events)
    state = Map.update!(state, :id, &(&1 + 2))
    {socket, state}

  {:info, socket, state = %{host: host},
   {{:slave, :host, host}, nil, %{owner: owner, name: name, live: live}}} ->
    state = Map.merge(state, %{owner: owner, name: name, live: live})
    {socket, state}

  {:info, socket, state, event} ->
    Log.trace(info: path, event: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Log.trace(close: path, reason: reason)
    :ok
end

Terminal.view(path, handler, auth: auth)
