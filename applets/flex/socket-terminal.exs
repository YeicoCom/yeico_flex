use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Socket Terminal">
    <div class="flex flex-col w-full h-full">
      <.fui fun={@ui.link} phx-click="click:connect" class="flex items-center gap-2 p-2 hover:rounded hover:bg-zinc-800">
        <div class="hero-plus"/>Connect
      </.fui>
      <div :if={@conn.params} class="pt-2 px-2 flex">
        <div>{@conn.params.ip}:{@conn.params.port}</div>
        <div class="grow"/>
        <.fui :if={@conn.on} fun={@ui.link} phx-click="click:disconnect" type="danger">Disconnect</.fui>
      </div>
      <form :if={@conn.on} phx-submit="input:submit" class="flex px-1 py-2 gap-2">
        <.fui fun={@ui.input} name="line" type="text" class="grow"/>
        <.fui fun={@ui.button} type="submit">Send</.fui>
      </form>
      <div :if={@count > 0} phx-update="stream" id="logs" phx-hook="AutoScroll"
        class="p-2 grow flex flex-col overflow-y-scroll font-mono rounded bg-zinc-800">
        <div :for={{id, %{dt: dt, style: style, line: line}} <- @streams.logs}
          id={id} class={[style, "break-all"]}>{dt} {line}</div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px]">
    <form phx-submit="modal:submit" class="flex flex-col gap-4">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>IP</div>
        <.fui fun={@ui.input} name="ip" value={@input.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={@input.port} type="number" step="1" min="1" max="65535" required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

loop = fn loop, parent, conn = %{socket: socket} ->
  receive do
    {:tcp, ^socket, data} ->
      send(parent, {:socket, self(), :input, data})
      loop.(loop, parent, conn)

    {:write, data} ->
      with :ok <- Tcp.write(conn, data) do
        loop.(loop, parent, conn)
      else
        {:error, error} ->
          send(parent, {:socket, self(), :error, error: error})
          Api.warn(error: error)
      end

    unexpected ->
      send(parent, {:socket, self(), :error, unexpected: unexpected})
      Api.warn(unexpected: unexpected)
  end
end

setup = fn {parent, %{ip: ip, port: port}} ->
  with {:ok, conn} <- Tcp.connect(ip, port, toms: 4_000, line: true, active: true) do
    send(parent, {:socket, self(), :success, "Connected to #{ip}:#{port}"})
    loop.(loop, parent, conn)
  else
    {:error, error} ->
      send(parent, {:socket, self(), :error, error: error})
      Api.warn(error: error)
  end
end

style = fn
  :error -> "text-red-500"
  :input -> "text-blue-500"
  :output -> "text-purple-500"
  :success -> "text-lime-500"
end

append = fn socket, state = %{id: id, tzoffset: tzoffset}, type, line ->
  dt = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: tzoffset) |> NaiveDateTime.to_time()
  log = %{id: id, dt: dt, style: style.(type), line: line}
  socket = stream(socket, :logs, [log])
  state = Map.update!(state, :count, &(&1 + 1))
  state = Map.update!(state, :id, &(&1 + 1))
  {socket, state}
end

title = "Connection Settings"

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Socket Terminal")
    socket = assign(socket, page_suffix: " · Flex")
    socket = stream(socket, :logs, [])
    state = Map.put(state, :input, %{port: 4401, ip: "127.0.0.1"})
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :conn, %{task: nil, params: nil, on: false})
    state = Map.put(state, :modal, %{title: title})
    state = Map.put(state, :count, 0)
    state = Map.put(state, :id, 0)
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

  {:event, socket, state = %{conn: %{task: %{pid: pid}}}, event = "input:submit",
   params = %{"line" => line}} ->
    Api.trace(view: path, event: event, params: params)
    send(pid, {:write, [line, "\n"]})
    append.(socket, state, :output, line)

  {:event, socket, state = %{conn: %{task: task}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    params = Enum.into(params, %{})
    state = Map.put(state, :input, params)
    if task, do: Api.kill(task)
    task = Api.async(setup, {self(), params})
    conn = %{params: params, task: task, on: true}
    state = Map.put(state, :conn, conn)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "click:connect", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, %{title: title})
    {socket, state}

  {:event, socket, state = %{conn: %{task: task}}, event = "click:disconnect", params} ->
    Api.trace(view: path, event: event, params: params)
    if task, do: Api.kill(task)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{conn: %{task: %{pid: pid}}}, event = {:socket, pid, :input, data}} ->
    Api.trace(view: path, info: event)
    append.(socket, state, :input, data)

  {:info, socket, state = %{conn: %{task: %{pid: pid}}}, event = {:socket, pid, type, data}} ->
    Api.trace(view: path, info: event)
    data = if is_binary(data), do: data, else: inspect(data)
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
