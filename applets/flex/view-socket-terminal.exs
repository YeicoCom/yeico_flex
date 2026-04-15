use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Socket Terminal">
    <div class="flex flex-col w-full h-full">
      <div class="pt-2 px-2 flex">
        <.fui fun={@ui.link} phx-click="click:connect">
          <div class="hero-link"/>Connect
        </.fui>
        <div class="grow"/>
        <.fui :if={@conn.on} fun={@ui.link} phx-click="click:disconnect" type="danger">
          <div class="hero-x-mark"/>Disconnect from {@conn.input.ip}:{@conn.input.port}
        </.fui>
      </div>
      <form id="output_form" :if={@conn.on} phx-submit="output:submit" phx-change="output:change"
        class="flex pt-2 px-1 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.select} name="omode" value={@output[:omode]} values={@options.omode} required title="Output Mode"/>
        <.fui fun={@ui.select} name="imode" value={@output[:imode]} values={@options.imode} required title="Input Mode"/>
        <.fui fun={@ui.input} name="line" value={@output[:line]} type="text" class="grow" id="output_form_line"
          phx-hook="LineHistory" data-key="socket-terminal"/>
        <.fui fun={@ui.button} type="submit">Send</.fui>
      </form>
      <div :if={@count > 0} phx-update="stream" id="logs" phx-hook="AutoScroll"
        class="mt-2 p-2 grow flex flex-col overflow-y-scroll font-mono rounded bg-zinc-800">
        <div :for={{id, %{dt: dt, style: style, line: line}} <- @streams.logs}
          id={id} class={[style, "break-all"]}>{dt} {line}</div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px]">
    <% input = @modal.input %>
    <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4" phx-hook="EnterNavigation" phx-update="ignore"
      autocomplete="off">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>IP</div>
        <.fui fun={@ui.input} name="ip" value={input.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"
          id="modal_form_ip" phx-hook="AutoFocus"/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={input.port} type="number" step="1" min="1" max="65535" required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

isend = fn parent, data ->
  send(parent, {:socket, self(), :input, data})
end

loop = fn loop, parent, conn = %{socket: socket}, eol, buffer ->
  receive do
    {:tcp, ^socket, data} ->
      if eol do
        buffer = buffer <> data
        parts = String.split(buffer, eol)
        max = length(parts) - 1
        indexed = Enum.with_index(parts)
        Enum.each(indexed, fn {data, i} -> if(i < max, do: isend.(parent, data <> eol)) end)
        loop.(loop, parent, conn, eol, Enum.at(parts, max))
      else
        isend.(parent, buffer <> data)
        loop.(loop, parent, conn, eol, "")
      end

    {:eol, eol} ->
      if byte_size(buffer) > 0, do: isend.(parent, buffer)
      loop.(loop, parent, conn, eol, "")

    {:write, data} ->
      with :ok <- Tcp.write(conn, data) do
        loop.(loop, parent, conn, eol, buffer)
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

setup = fn {parent, %{ip: ip, port: port}, eol} ->
  with {:ok, conn} <- Tcp.connect(ip, port, toms: 4_000, line: false, active: true) do
    send(parent, {:socket, self(), :success, "Connected to #{ip}:#{port}"})
    loop.(loop, parent, conn, eol, "")
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

printable = fn line ->
  line
  |> String.split(~r/[[:graph:]]+/, include_captures: true)
  |> Enum.with_index()
  |> Enum.map(fn {chunk, i} ->
    case {rem(i, 2), chunk} do
      {0, ""} -> ""
      {0, chunk} -> ["[", :binary.encode_hex(chunk), "]"]
      {1, _} -> chunk
    end
  end)
  |> Enum.join("")
end

append = fn socket, state = %{id: id, tzoffset: tzoffset}, type, line ->
  line =
    case type do
      :input -> printable.(line)
      :output -> printable.(line)
      _ -> line
    end

  dt = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: tzoffset) |> NaiveDateTime.to_time()
  log = %{id: id, dt: dt, style: style.(type), line: line}
  socket = stream(socket, :logs, [log])
  state = Map.update!(state, :count, &(&1 + 1))
  state = Map.update!(state, :id, &(&1 + 1))
  {socket, state}
end

title = "Connection Settings"
omode = ["Append CR+NL", "Append CR", "Append NL", "Append None", "Hexadecimal", "Mixed"]
imode = ["Packet NL", "Packet CR", "Stream"]
options = %{omode: omode, imode: imode}

toeol = fn
  "Packet NL" -> "\n"
  "Packet CR" -> "\r"
  "Stream" -> nil
end

hex2bin = fn line ->
  line
  |> String.split(~r/[[:xdigit:]]+/, include_captures: true)
  |> Enum.with_index()
  |> Enum.map(fn {chunk, i} ->
    case rem(i, 2) do
      0 ->
        ""

      1 ->
        len = String.length(chunk)
        len = if rem(len, 2) == 1, do: len + 1, else: len
        chunk = String.pad_leading(chunk, len, "0")
        chunk = String.upcase(chunk)
        Base.decode16!(chunk)
    end
  end)
  |> Enum.join("")
end

mix2bin = fn line ->
  line
  |> String.split(~r/\[[[:xdigit:]]+]/, include_captures: true)
  |> Enum.with_index()
  |> Enum.map(fn {chunk, i} ->
    case rem(i, 2) do
      0 ->
        chunk

      1 ->
        chunk
        |> String.trim_leading("[")
        |> String.trim_trailing("]")
        |> (fn chunk ->
              len = String.length(chunk)
              len = if rem(len, 2) == 1, do: len + 1, else: len
              String.pad_leading(chunk, len, "0")
            end).()
        |> String.upcase()
        |> Base.decode16!()
    end
  end)
  |> Enum.join("")
end

transform = fn
  "Append CR+NL", line -> line <> "\r\n"
  "Append CR", line -> line <> "\r"
  "Append NL", line -> line <> "\n"
  "Append None", line -> line
  "Hexadecimal", line -> hex2bin.(line)
  "Mixed", line -> mix2bin.(line)
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    initial = %{port: 4401, ip: "127.0.0.1"}
    [ifirst | _] = imode
    [ofirst | _] = omode
    output = %{imode: ifirst, omode: ofirst, line: ""}
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Socket Terminal")
    socket = assign(socket, page_suffix: " · Flex")
    socket = stream(socket, :logs, [])
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :conn, %{task: nil, input: initial, on: false})
    state = Map.put(state, :modal, %{title: title, input: initial})
    state = Map.put(state, :options, options)
    state = Map.put(state, :output, output)
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

  {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}}, event = "output:change",
   params = %{"line" => line, "omode" => omode, "imode" => imode, "_target" => targets}} ->
    Api.trace(view: path, event: event, params: params)
    if "imode" in targets, do: send(pid, {:eol, toeol.(imode)})
    output = Map.put(output, :line, line)
    output = Map.put(output, :omode, omode)
    output = Map.put(output, :imode, imode)
    state = Map.put(state, :output, output)
    {socket, state}

  {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}}, event = "output:submit",
   params = %{"line" => line, "omode" => omode}} ->
    Api.trace(view: path, event: event, params: params)
    transformed = transform.(omode, line)
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
    task = Api.async(setup, {self(), params, toeol.(imode)})
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
