defmodule Flex.ModbusTerminal.Index do
  alias Flex.ModbusTerminal.IUtils
  use Flex.Live

  def view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Modbus Terminal">
      <div class="flex flex-col w-full h-full gap-2">
        <div class="px-2 flex">
          <.fui fun={&UI.link/1} phx-click="click:connect">
            <div class="hero-link"/>Connect to Modbus Device
          </.fui>
          <div class="grow"/>
          <.fui :if={@conn.on} fun={&UI.link/1} phx-click="click:disconnect" type="danger">
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
          <.fui fun={&UI.input/1} name="line" value={@output.line} type="text" class="grow" id="output_form_line"
            phx-hook="LineHistory" data-key="modbus-terminal" title={@help}/>
          <.fui fun={&UI.button/1} type="submit">Execute</.fui>
        </form>
        <div :if={@conn.on} class="px-2">{@tip}</div>
      </div>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
      <% input = @modal.input %>
      <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4"
        phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <div>IP</div>
          <.fui fun={&UI.input/1} name="ip" value={input.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"
            id="modal_autofocus" phx-hook="AutoFocus"/>
          <div>Port</div>
          <.fui fun={&UI.input/1} name="port" value={input.port} type="number" step="1" min="1" max="65535" required/>
          <div>Protocol</div>
          <.fui fun={&UI.select/1} name="proto" value={input.proto} values={@options.protos} required/>
        </div>
        <.fui fun={&UI.button/1} type="submit" class="col-span-2">Accept</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)

    fn
      {:mount, socket, state} ->
        tzoffset = socket.assigns.tzoffset || 0
        pfirst = List.first(IUtils.options().protos)
        initial = %{port: 44001, ip: "127.0.0.1", proto: pfirst}
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Modbus Terminal")
        socket = assign(socket, page_suffix: " · Flex")
        socket = stream(socket, :logs, [])
        state = Map.put(state, :conn, %{task: nil, input: initial, on: false})
        state = Map.put(state, :modal, %{title: IUtils.title(), input: initial})
        state = Map.put(state, :options, IUtils.options())
        state = Map.put(state, :help, Mb.help_full())
        state = Map.put(state, :tip, Mb.help_short())
        state = Map.put(state, :output, %{line: nil})
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :logid, 0)
        state = Ln.init(socket, state)
        {socket, state}

      {:params, socket, state = %{login?: true, user: nil}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        socket = Ln.forward(socket, path, uri)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        {socket, state}

      {:render, assigns, state} ->
        state = Map.put(state, :streams, assigns.streams)
        view(state)

      {:event, socket, state, event = "modal:close", params} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{output: output}, event = "output:change",
       params = %{"line" => line}} ->
        Log.trace(view: path, event: event, params: params)
        output = Map.put(output, :line, line)
        state = Map.put(state, :output, output)
        {socket, state}

      {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}},
       event = "output:submit", params = %{"line" => line}} ->
        Log.trace(view: path, event: event, params: params)

        case Mb.safe_parse(line) do
          {:ok, res} ->
            send(pid, {:exec, res})
            output = Map.put(output, :line, nil)
            state = Map.put(state, :output, output)
            socket = push_event(socket, "history:append", %{line: line})
            IUtils.append(socket, state, :trace, line)

          {:error, error} ->
            IUtils.append(socket, state, :error, error)
        end

      {:event, socket, state = %{conn: %{task: task}}, event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        params = Map.update!(params, "port", &String.to_integer/1)
        params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
        if task, do: Api.kill(task)
        task = Api.async(&IUtils.setup/1, [{:parent, self()} | params])
        conn = %{input: Enum.into(params, %{}), task: task, on: true}
        state = Map.put(state, :conn, conn)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{conn: %{input: input}}, event = "click:connect", params} ->
        Log.trace(view: path, event: event, params: params)
        modal = %{title: IUtils.title(), input: input}
        state = Map.put(state, :modal, modal)
        {socket, state}

      {:event, socket, state = %{conn: %{task: task}}, event = "click:disconnect", params} ->
        Log.trace(view: path, event: event, params: params)
        if task, do: Api.kill(task)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{conn: %{task: %{pid: pid}}}, event = {:socket, pid, type, data}} ->
        Log.trace(view: path, info: event)
        IUtils.append(socket, state, type, data)

      {:info, socket, state = %{conn: conn = %{task: %{pid: pid}}},
       event = {:DOWN, _, :process, pid, _}} ->
        Log.trace(view: path, info: event)
        conn = Map.put(conn, :on, false)
        state = Map.put(state, :conn, conn)
        IUtils.append(socket, state, :error, "Disconnected")

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, reason} ->
        Log.trace(view: path, close: reason)
        :ok
    end
  end
end

:ok
