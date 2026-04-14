use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Serial Exports">
    <div class="flex flex-col gap-2">
      <.fui fun={@ui.link} phx-click="click:add" class="flex center-items gap-2"><div class="hero-plus"/>Add</.fui>
      <div :for={{id, export} <- @exports} class="flex flex-col">
        <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
          {export.tty},{export.bauds},{export.ip}:{export.port},{export.status}
        </.fui>
        <div class="flex gap-2">
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="local">Local</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="remote">Remote</.fui>
          <div class="flex-grow"></div>
          <.fui fun={@ui.link} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
        </div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px]">
    <form phx-submit="modal:submit" class="flex mt-4 gap-4">
      <.fui fun={@ui.select} name="tty" value={@input.tty} values={@options.ttys} class="min-w-[120px] overflow-x-auto" size="4" required/>
      <div class="flex flex-col gap-2 justify-between">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <div>Bauds</div>
          <.fui fun={@ui.select} name="bauds" value={@input.bauds} values={@options.bauds} required/>
          <div>IP</div>
          <.fui fun={@ui.select} name="ip" value={@input.ip} values={@options.ips} required/>
          <div>Port</div>
          <.fui fun={@ui.input} name="port" value={@input.port} type="number" step="1" min="1024" max="65535" required/>
          <div>Status</div>
          <.fui fun={@ui.select} name="status" value={@input.status} values={@options.status} required/>
        </div>
        <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
      </div>
    </form>
  </.fui>
  """
end

new = %{tty: "/dev/ttyUSB0", bauds: 115_200, port: 4000, ip: "127.0.0.1", status: :enabled}
ips = ["127.0.0.1", "0.0.0.0"]
bauds = [9600, 115_200]
status = [:enabled, :disabled]
options = %{status: status, bauds: bauds, ips: ips}

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Serial Exports")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :exports, Api.subget!("flex:serial:exports"))
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
    state = Map.drop(state, [:input, :options])
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

    state = Map.drop(state, [:input, :options])
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
    state = Map.put(state, :modal, %{title: "New Serial Export"})
    state = Map.put(state, :input, new)
    state = Map.put(state, :options, options)
    {socket, state}

  {:event, socket, state, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    exports = state.exports |> Enum.into(%{})
    export = exports[id]
    ttys = [export.tty | serial.(:list)] |> Enum.uniq()
    state = Map.put(state, :modal, %{title: "Edit Serial Export"})
    options = Map.put(options, :ttys, ttys)
    options = Map.put(options, :id, id)
    state = Map.put(state, :input, export)
    state = Map.put(state, :options, options)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:serial:" <> key, _, value}} ->
    Api.trace(view: path, info: event)
    key = String.to_atom(key)
    state = Map.put(state, key, value)
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
