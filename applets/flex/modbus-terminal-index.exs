use Terminal.Live

help = """
Values are decimal by default and can be prefixed with:
  h for hexadecimal
  d for decimal
  b for binary

s: Slave [0-255] or [h00-hFF]
a: Address [0-65535] or [h0000-hFFFF]
c: Code
  rdi to read digital input(s)
  rdo to read digital output(s)
  wdo to write digital output(s)
  rri to read register input(s)
  rro to read register output(s)
  wro to write register output(s)
  ri to read input point(s)
  rc to read discrete coil(s)
  fc to force discrete coil(s)
  rir to read input register(s)
  rhr to read holding register(s)
  phr to preset holding register(s)
d: Read count
  or binary encoded digital data to output
  or colon separated register data to output
e: Encoding
  f32be 32 bit big endian IEEE754 float encoding
  f32le 32 bit little endian IEEE754 float encoding
  u16be 16 bit big endian unsigned integer
  u16le 16 bit little endian unsigned integer
#: Name or comment
"""

tip = "s=Slave,a=Address,c=[rdi,rdo,wdo,rri,rro,wro],d=Data,e=[f32be,f32le,u16be,u16le]#Comment"

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Modbus Terminal">
    <div class="flex flex-col w-full h-full gap-2">
      <div class="px-2 flex">
        <.fui fun={@ui.link} phx-click="click:connect">
          <div class="hero-link"/>Connect to Modbus Device
        </.fui>
        <div class="grow"/>
        <.fui :if={@conn.on} fun={@ui.link} phx-click="click:disconnect" type="danger">
          <div class="hero-x-mark"/>Disconnect from {@conn.input.proto}:{@conn.input.ip}:{@conn.input.port}
        </.fui>
      </div>
      <div phx-update="stream" id="logs" phx-hook="AutoScroll"
        class="p-2 grow flex flex-col overflow-y-scroll select-text font-mono rounded bg-zinc-800">
        <div :for={{id, %{dt: dt, style: style, line: line}} <- @streams.logs}
          id={id} class={[style, "break-all"]}>{dt} {line}</div>
      </div>
      <form id="output_form" :if={@conn.on} phx-submit="output:submit" phx-change="output:change"
        class="flex px-1 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.input} name="line" value={@output.line} type="text" class="grow" id="output_form_line"
          phx-hook="LineHistory" data-key="modbus-terminal" title={@help}/>
        <.fui fun={@ui.button} type="submit">Execute</.fui>
      </form>
      <div :if={@conn.on} class="px-2">{@tip}</div>
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
        <div>Protocol</div>
        <.fui fun={@ui.select} name="proto" value={input.proto} values={@options.protos} required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

style = fn
  :trace -> "text-gray-200"
  :error -> "text-red-500"
  :input -> "text-blue-500"
  :output -> "text-purple-500"
  :success -> "text-lime-500"
end

encode = fn
  :input, line -> Base.encode16(line)
  :output, line -> Base.encode16(line)
  _, line -> line
end

append = fn socket, state = %{logid: logid, tzoffset: tzoffset}, type, line ->
  line = if is_binary(line), do: line, else: inspect(line)
  line = encode.(type, line)
  dt = NaiveDateTime.utc_now()
  log = %{id: logid, dt: dt, style: style.(type), line: line}
  log = lib.shift.(tzoffset, log)
  socket = stream(socket, :logs, [log])
  state = Map.update!(state, :logid, &(&1 + 1))
  {socket, state}
end

title = "Modbus Connection"

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    pfirst = List.first(lib.options.protos)
    initial = %{port: 44001, ip: "127.0.0.1", proto: pfirst}
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Modbus Terminal")
    socket = assign(socket, page_suffix: " · Flex")
    socket = stream(socket, :logs, [])
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :conn, %{task: nil, input: initial, on: false})
    state = Map.put(state, :modal, %{title: title, input: initial})
    state = Map.put(state, :options, lib.options)
    state = Map.put(state, :output, %{line: nil})
    state = Map.put(state, :help, help)
    state = Map.put(state, :logid, 0)
    state = Map.put(state, :tip, tip)
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

  {:event, socket, state = %{output: output}, event = "output:change", params = %{"line" => line}} ->
    Api.trace(view: path, event: event, params: params)
    output = Map.put(output, :line, line)
    state = Map.put(state, :output, output)
    {socket, state}

  {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}}, event = "output:submit",
   params = %{"line" => line}} ->
    Api.trace(view: path, event: event, params: params)

    case lib.parse.(line) do
      {:ok, res} ->
        send(pid, {:exec, res})
        output = Map.put(output, :line, nil)
        state = Map.put(state, :output, output)
        socket = push_event(socket, "history:append", %{line: line})
        append.(socket, state, :trace, line)

      {:error, error} ->
        append.(socket, state, :error, error)
    end

  {:event, socket, state = %{conn: %{task: task}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    params = Enum.into(params, %{})
    if task, do: Api.kill(task)
    task = Api.async(lib.setup, {self(), params})
    conn = %{input: params, task: task, on: true}
    state = Map.put(state, :conn, conn)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{conn: %{input: input}}, event = "click:connect", params} ->
    Api.trace(view: path, event: event, params: params)
    modal = %{title: title, input: input}
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
