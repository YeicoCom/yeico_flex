use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Modbus Devices">
    <div class="flex flex-col w-full h-full overflow-y-auto">
      <div class="p-2 flex">
        <.fui fun={@ui.link} phx-click="click:add">
        <div class="hero-plus"/>Add Modbus Device
        </.fui>
        <div class="grow"/>
      </div>
      <div :for={id <- @index} class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
        <% item = @devices[id] %>
        <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
          {item.proto},{item.ip}:{item.port},{item.status}:{item.name}
        </.fui>
        <div class="flex gap-2">
          <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
          <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
          <div class="grow"></div>
          <.fui fun={@ui.link} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
        </div>
        <% log = @logs[id] %>
        <div :if={item.status==:enabled and log} class={[
          log.level == :error && "text-red-500",
          log.level == :error || "text-neutral-500",
        ]}>{log.dt} {log.msg}</div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px]">
    <% input = @modal.input %>
    <form phx-submit="modal:submit" class="flex flex-col mt-4 gap-4" id="modal_form" phx-hook="EnterNavigation" phx-update="ignore">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Name</div>
        <.fui fun={@ui.input} name="name" value={input.name} type="text" required phx-hook="AutoFocus"/>
        <div>Protocol</div>
        <.fui fun={@ui.select} name="proto" value={input.proto} values={@options.protos} required/>
        <div>IP</div>
        <.fui fun={@ui.input} name="ip" value={input.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={input.port} type="number" step="1" min="1" max="65535" required/>
        <div>Status</div>
        <.fui fun={@ui.select} name="status" value={input.status} values={@options.status} required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

new_modal = fn state ->
  options = moddev.options
  modal = %{title: "New Modbus Device", input: moddev.new.()}
  state = Map.put(state, :modal, modal)
  Map.put(state, :options, options)
end

edit_modal = fn state, id, device ->
  options = moddev.options
  modal = %{title: "Edit Modbus Device", input: device}
  state = Map.put(state, :modal, modal)
  state = Map.put(state, :id, id)
  Map.put(state, :options, options)
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

apply = fn moddev, action ->
  case action do
    "enable" -> Map.put(moddev, :status, :enabled)
    "disable" -> Map.put(moddev, :status, :disabled)
  end
end

parse = fn params ->
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{})
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:modbus:logs")
    logs = moddev.shift.(tzoffset, logs)
    devices = Api.subget!("flex:modbus:devices")
    index = index.(devices)
    devices = Enum.into(devices, %{})
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Modbus Devices")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :devices, devices)
    state = Map.put(state, :index, index)
    state = Map.put(state, :logs, logs)
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :ui, ui)
    state = Map.put(state, :id, nil)
    state = if length(index) > 0, do: state, else: new_modal.(state)
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

  {:event, socket, state = %{id: nil}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:insert", parse.(params))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{id: id}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:update", {id, parse.(params)})
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :id, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:delete", id)
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:update", {id, apply.(devices[id], action)})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = new_modal.(state)
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = edit_modal.(state, id, devices[id])
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:modbus:devices", _, devices}} ->
    Api.trace(view: path, info: event)
    index = index.(devices)
    devices = Enum.into(devices, %{})
    state = Map.put(state, :devices, devices)
    state = Map.put(state, :index, index)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:modbus:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, moddev.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
