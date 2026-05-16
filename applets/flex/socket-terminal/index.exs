defmodule Flex.SocketTerminal.Index do
  alias Flex.SocketTerminal.IUtils
  use Flex.Live

  def view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Socket Terminal">
      <div class="flex flex-col w-full h-full gap-2">
        <div class="px-2 flex">
          <.fui fun={&UI.link/1} phx-click="click:connect">
            <div class="hero-link"/>Connect to Socket
          </.fui>
          <div class="grow"/>
          <.fui :if={@conn.on} fun={&UI.link/1} phx-click="click:disconnect" type="danger">
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
            id={id} class={[style, hexa && "grid-cols-2", !hexa && "grid-cols-1", "grid gap-2 px-2 hover:bg-zinc-900"]}>
            <div class="break-all whitespace-pre-wrap">{dt} {text}</div>
            <div :if={hexa} class="break-all">{hexa}</div>
          </div>
        </div>
        <form id="output_form" :if={@conn.on} phx-submit="output:submit" phx-change="output:change"
          class="flex pb-1 px-1 gap-2" phx-hook="EnterNavigation" autocomplete="off">
          <.fui fun={&UI.input/1} name="line" value={@output.line} type="text" class="grow" id="output_form_line"
            phx-hook="LineHistory" data-key="socket-terminal"/>
          <.fui fun={&UI.button/1} type="submit">Send</.fui>
          <.fui fun={&UI.select/1} name="omode" value={@output.omode} values={@options.omode} required title="Output Mode"/>
          <.fui fun={&UI.select/1} name="imode" value={@output.imode} values={@options.imode} required title="Input Mode"/>
        </form>
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
        options = IUtils.options()
        ifirst = List.first(options.imode)
        ofirst = List.first(options.omode)
        output = %{imode: ifirst, omode: ofirst, line: nil}
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Socket Terminal")
        socket = assign(socket, page_suffix: " · Flex")
        socket = stream(socket, :logs, [])
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :conn, %{task: nil, input: IUtils.initial(), on: false})
        state = Map.put(state, :modal, %{title: IUtils.title(), input: IUtils.initial()})
        state = Map.put(state, :options, options)
        state = Map.put(state, :output, output)
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

      {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}},
       event = "output:change",
       params = %{"line" => line, "omode" => omode, "imode" => imode, "_target" => targets}} ->
        Log.trace(view: path, event: event, params: params)
        if "imode" in targets, do: send(pid, {:imode, imode})
        output = Map.put(output, :line, line)
        output = Map.put(output, :omode, omode)
        output = Map.put(output, :imode, imode)
        state = Map.put(state, :output, output)
        {socket, state}

      {:event, socket, state = %{output: output, conn: %{task: %{pid: pid}}},
       event = "output:submit", params = %{"line" => line, "omode" => omode}} ->
        Log.trace(view: path, event: event, params: params)
        transformed = IUtils.transform(omode, line)
        send(pid, {:write, transformed})
        output = Map.put(output, :line, nil)
        state = Map.put(state, :output, output)
        socket = push_event(socket, "history:append", %{line: line})
        IUtils.append(socket, state, :output, transformed)

      {:event, socket, state = %{conn: %{task: task}, output: %{imode: imode}},
       event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        params = Map.update!(params, "port", &String.to_integer/1)
        params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
        if task, do: Api.kill(task)
        opts = Keyword.merge(params, parent: self(), imode: imode)
        params = Enum.into(params, %{})
        tag = "socketterminal:#{params.ip}:#{params.port}"
        task = Api.async(tag, &IUtils.setup/1, opts)
        conn = %{input: params, task: task, on: true}
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
