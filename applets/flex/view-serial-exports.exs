use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Serial Exports">
    <div class="flex flex-col w-full h-full overflow-y-auto">
      <div class="p-2 flex">
        <.fui fun={@ui.link} phx-click="click:add">
        <div class="hero-plus"/>Add Serial Export
        </.fui>
        <div class="grow"/>
      </div>
      <div :for={id <- @index} class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
        <% export = @exports[id] %>
        <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
          {export.tty},{export.bauds}@{export.bits},{export.ip}:{export.port},{export.status}
        </.fui>
        <div class="flex gap-2">
          <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="local">Local</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="remote">Remote</.fui>
          <div class="grow"></div>
          <.fui fun={@ui.link} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
        </div>
        <% log = @logs[id] %>
        <div :if={export.status==:enabled and log} class={[
          log.level == :error && "text-red-500",
          log.level == :error || "text-neutral-500",
        ]}>{log.dt} {log.msg}</div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px]">
    <% input = @modal.input %>
    <form phx-submit="modal:submit" class="flex flex-col mt-4 gap-4" id="modal_form" phx-hook="EnterNavigation" phx-update="ignore">
      <.fui fun={@ui.select} name="tty" value={input.tty} values={@options.ttys} class="min-w-[120px] overflow-x-auto" size="4" required
        id="modal_form_tty" phx-hook="AutoFocus"/>
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Bauds</div>
        <.fui fun={@ui.select} name="bauds" value={input.bauds} values={@options.bauds} required/>
        <div>Bits</div>
        <.fui fun={@ui.select} name="bits" value={input.bits} values={@options.bits} required/>
        <div>IP</div>
        <.fui fun={@ui.select} name="ip" value={input.ip} values={@options.ips} required/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={input.port} type="number" step="1" min="1024" max="65535" required/>
        <div>Status</div>
        <.fui fun={@ui.select} name="status" value={input.status} values={@options.status} required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

new = %{
  tty: "/dev/ttyUSB0",
  bauds: 115_200,
  bits: "8n1",
  port: 4401,
  ip: "127.0.0.1",
  status: :enabled
}

bits = ["8n1"]
bauds = [9600, 115_200]
ips = ["127.0.0.1", "0.0.0.0"]
status = [:enabled, :disabled]
options = %{status: status, bauds: bauds, bits: bits, ips: ips}

shift_one = fn tzoffset, log = %{dt: dt} ->
  dt = NaiveDateTime.shift(dt, hour: tzoffset)
  dt = NaiveDateTime.to_time(dt)
  %{log | dt: dt}
end

shift_all = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, v} -> {k, shift_one.(tzoffset, v)} end)
  |> Enum.into(%{})
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:serial:logs")
    logs = shift_all.(tzoffset, logs)
    exports = Api.subget!("flex:serial:exports")
    index = index.(exports)
    exports = Enum.into(exports, %{})
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Serial Exports")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :exports, exports)
    state = Map.put(state, :index, index)
    state = Map.put(state, :logs, logs)
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Map.update!(params, "bauds", &String.to_integer/1)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    params = Enum.into(params, %{})

    case state[:options][:id] do
      nil -> Bus.broadcast!("flex:serial:insert", params)
      id -> Bus.broadcast!("flex:serial:update", {id, params})
    end

    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial:delete", id)
    {socket, state}

  {:event, socket, state, event = "click:action", params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    exports = state.exports |> Enum.into(%{})
    export = exports[id]

    export =
      case action do
        "enable" -> Map.put(export, :status, :enabled)
        "disable" -> Map.put(export, :status, :disabled)
        "local" -> Map.put(export, :ip, "127.0.0.1")
        "remote" -> Map.put(export, :ip, "0.0.0.0")
      end

    Bus.broadcast!("flex:serial:update", {id, export})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    options = Map.put(options, :ttys, serial.(:list))
    modal = %{title: "New Serial Export", input: new}
    state = Map.put(state, :modal, modal)
    state = Map.put(state, :options, options)
    {socket, state}

  {:event, socket, state, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    exports = state.exports |> Enum.into(%{})
    export = exports[id]
    ttys = [export.tty | serial.(:list)] |> Enum.uniq()
    modal = %{title: "Edit Serial Export", input: export}
    state = Map.put(state, :modal, modal)
    options = Map.put(options, :ttys, ttys)
    options = Map.put(options, :id, id)
    state = Map.put(state, :options, options)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:serial:exports", _, exports}} ->
    Api.trace(view: path, info: event)
    index = index.(exports)
    exports = Enum.into(exports, %{})
    state = Map.put(state, :exports, exports)
    state = Map.put(state, :index, index)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:serial:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, shift_all.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
