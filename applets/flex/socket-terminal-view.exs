use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Socket Terminal">
    <div class="flex flex-col w-full h-full gap-2">
      <div class="px-2 flex">
        <.fui fun={@ui.link} phx-click="click:connect">
          <div class="hero-link"/>Connect to Socket
        </.fui>
        <div class="grow"/>
        <.fui :if={@conn.on} fun={@ui.link} phx-click="click:disconnect" type="danger">
          <div class="hero-x-mark"/>Disconnect from {@conn.input.ip}:{@conn.input.port}
        </.fui>
      </div>
      <%!--
      break-all do not preserve word boundaries
      test std input: 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890 01234567890
      test hex input: 20313237322E34200D0A20313237322E34200D0A20313237322E34200D0A20313237322E34200D0A20313237322E34200D0A20313237322E34200D0A
      auto scroll working even with multi line entries
      fixed scrollbar on the right mistaken for padding
      --%>
      <div phx-update="stream" id="logs" phx-hook="AutoScroll"
        class="py-2 grow flex flex-col overflow-y-scroll select-text font-mono rounded bg-zinc-800">
        <div :for={{id, %{dt: dt, style: style, text: text, hexa: hexa}} <- @streams.logs}
          id={id} class={[style, hexa && "grid-cols-2", hexa || "grid-cols-1", "grid gap-2 px-2 hover:bg-zinc-900"]}>
          <div class="break-all whitespace-pre-wrap">{dt} {text}</div>
          <div :if={hexa} class="break-all">{hexa}</div>
        </div>
      </div>
      <form id="output_form" :if={@conn.on} phx-submit="output:submit" phx-change="output:change"
        class="flex pb-1 px-1 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.input} name="line" value={@output.line} type="text" class="grow" id="output_form_line"
          phx-hook="LineHistory" data-key="socket-terminal"/>
        <.fui fun={@ui.button} type="submit">Send</.fui>
        <.fui fun={@ui.select} name="omode" value={@output.omode} values={@options.omode} required title="Output Mode"/>
        <.fui fun={@ui.select} name="imode" value={@output.imode} values={@options.imode} required title="Input Mode"/>
      </form>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
    <% input = @modal.input %>
    <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4"
      phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>IP</div>
        <.fui fun={@ui.input} name="ip" value={input.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"
          id="modal_autofocus" phx-hook="AutoFocus"/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={input.port} type="number" step="1" min="1" max="65535" required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

append = fn socket, state = %{logid: logid, tzoffset: tzoffset}, type, line ->
  hexa =
    case type do
      :input -> Base.encode16(line)
      :output -> Base.encode16(line)
      _ -> nil
    end

  text =
    case type do
      :input -> lib.printable.(line)
      :output -> lib.printable.(line)
      _ -> if is_binary(line), do: line, else: inspect(line)
    end

  dt = NaiveDateTime.utc_now()
  log = %{id: logid, dt: dt, style: lib.style.(type), text: text, hexa: hexa}
  log = lib.shift.(tzoffset, log)
  socket = stream(socket, :logs, [log])
  state = Map.update!(state, :logid, &(&1 + 1))
  {socket, state}
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    ifirst = List.first(lib.options.imode)
    ofirst = List.first(lib.options.omode)
    output = %{imode: ifirst, omode: ofirst, line: nil}
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Socket Terminal")
    socket = assign(socket, page_suffix: " · Flex")
    socket = stream(socket, :logs, [])
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :conn, %{task: nil, input: lib.initial, on: false})
    state = Map.put(state, :modal, %{title: lib.title, input: lib.initial})
    state = Map.put(state, :options, lib.options)
    state = Map.put(state, :output, output)
    state = Map.put(state, :logid, 0)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:render, assigns, state} ->
    state = Map.put(state, :streams, assigns.streams)
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}}, event = "output:change",
   params = %{"line" => line, "omode" => omode, "imode" => imode, "_target" => targets}} ->
    Api.trace(view: path, event: event, params: params)
    if "imode" in targets, do: send(pid, {:eol, lib.toeol.(imode)})
    output = Map.put(output, :line, line)
    output = Map.put(output, :omode, omode)
    output = Map.put(output, :imode, imode)
    state = Map.put(state, :output, output)
    {socket, state}

  {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}}, event = "output:submit",
   params = %{"line" => line, "omode" => omode}} ->
    Api.trace(view: path, event: event, params: params)
    transformed = lib.transform.(omode, line)
    send(pid, {:write, transformed})
    output = Map.put(output, :line, nil)
    state = Map.put(state, :output, output)
    socket = push_event(socket, "history:append", %{line: line})
    append.(socket, state, :output, transformed)

  {:event, socket, state = %{conn: %{task: task}, output: %{imode: imode}},
   event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    params = Enum.into(params, %{})
    if task, do: Api.kill(task)
    task = Api.async(lib.setup, {self(), params, lib.toeol.(imode)})
    conn = %{input: params, task: task, on: true}
    state = Map.put(state, :conn, conn)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{conn: %{input: input}}, event = "click:connect", params} ->
    Api.trace(view: path, event: event, params: params)
    modal = %{title: lib.title, input: input}
    state = Map.put(state, :modal, modal)
    {socket, state}

  {:event, socket, state = %{conn: %{task: task}}, event = "click:disconnect", params} ->
    Api.trace(view: path, event: event, params: params)
    if task, do: Api.kill(task)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{conn: %{task: %{pid: pid}}}, event = {:socket, pid, type, data}} ->
    Api.trace(view: path, info: event)
    append.(socket, state, type, data)

  {:info, socket, state = %{conn: conn = %{task: %{pid: pid}}},
   event = {:DOWN, _, :process, pid, _}} ->
    Api.trace(view: path, info: event)
    conn = Map.put(conn, :on, false)
    state = Map.put(state, :conn, conn)
    append.(socket, state, :error, "Disconnected")

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
