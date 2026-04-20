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
      <div :for={id <- @index} class="flex flex-col p-2">
        <% item = @devices[id] %>
        <div class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
          <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
            {item.proto},{item.ip}:{item.port},{item.status},{item.name}
          </.fui>
          <div class="flex gap-2">
            <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
            <.fui fun={@ui.link} phx-click="click:points" phx-value-id={id}>Points</.fui>
            <div class="grow"></div>
            <.fui fun={@ui.link} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
          </div>
          <% log = @logs[id] %>
          <div :if={item.status==:enabled and log} class={[
            log.error? && "text-red-500",
            log.error? || "text-neutral-500",
          ]}>{log.dt} {log.msg}</div>
        </div>
        <div class="flex flex-col p-1">
          <div :for={{point, pi} <- Enum.with_index(item.points)}>

            s:{point.slave} a:{point.address} t:{point.type}
            <div :for={name <- @points[id][pi]}>
              n:{name} v:{@points[id]["#{point.type}:#{name}"]}
            </div>
          </div>
        </div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal && !@modal.points?} title={@modal.title} class="min-w-[360px]">
    <% input = @modal.input %>
    <form id="modal_form" phx-submit="modal:submit" class="flex flex-col mt-4 gap-4" phx-hook="EnterNavigation" phx-update="ignore">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Name</div>
        <.fui fun={@ui.input} name="name" value={input.name} type="text" required phx-hook="AutoFocus" pattern="^[a-zA-Z0-9_,]+$"/>
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
  <.fui fun={@ui.modal} :if={@modal && @modal.points?} title={@modal.title}
    class="min-w-[360px] max-h-[80%] h-[80%] flex flex-col" away="ignore:away">
    <% input = @modal.input %>
    <div class="grow overflow-y-hidden">
      <form id="modal_form" phx-submit="modal:points:submit" phx-change="modal:points:change"
        class="h-full flex flex-col gap-1" phx-hook="EnterNavigation">
        <div>{input.proto},{input.ip}:{input.port},{input.status},{input.name}</div>
        <div class="grid grid-cols-[3em_4em_3em_24em_1fr] gap-1">
          <div>Slave</div>
          <div>Address</div>
          <div>Type</div>
          <div>Name(s)</div>
          <.fui fun={@ui.link} phx-click="click:point:add" phx-value-pi={0}><div class="hero-plus z-0"/>Point</.fui>
        </div>
        <div class="grow overflow-y-scroll flex flex-col gap-1 p-1">
          <% pl = length(input.points) - 1 %>
          <%= for {point, pi} <- Enum.with_index(input.points) do %>
            <div class="grid grid-cols-[3em_4em_3em_24em_1fr] gap-1">
              <.fui fun={@ui.input} name="slave[]" value={point.slave} type="number" step="1" min="0" max="255" required/>
              <.fui fun={@ui.input} name="address[]" value={point.address} type="number" step="1" min="0" max="65535" required/>
              <.fui fun={@ui.select} name="type[]" value={point.type} values={@options.points.types} required/>
              <.fui fun={@ui.input} name="names[]" value={point.names} type="text" required pattern="^[a-zA-Z0-9_,]+$"/>
              <div class="flex gap-1">
                <.fui fun={@ui.link} disabled={pi==0} phx-click="click:point:del" phx-value-pi={pi}><div class="hero-x-mark z-0"/></.fui>
                <.fui fun={@ui.link} disabled={pi==0} phx-click="click:point:up" phx-value-pi={pi}><div class="hero-arrow-up z-0"/></.fui>
                <.fui fun={@ui.link} disabled={pi==pl} phx-click="click:point:down" phx-value-pi={pi}><div class="hero-arrow-down z-0"/></.fui>
              </div>
            </div>
          <% end %>
        </div>
        <.fui fun={@ui.button} type="submit" class="mt-2">Accept</.fui>
      </form>
    </div>
  </.fui>
  """
end

modal = fn
  {state, id, device = %{points: points}, true} ->
    options = lib.options
    points = if length(points) > 0, do: points, else: points ++ [lib.points.new]
    device = Map.put(device, :points, points)
    modal = %{title: "Edit Modbus Points", id: id, input: device, points?: true}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)

  {state, id, device, false} ->
    options = lib.options
    modal = %{title: "Edit Modbus Device", id: id, input: device, points?: false}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)

  state ->
    options = lib.options
    modal = %{title: "Add Modbus Device", id: nil, input: lib.new.(), points?: false}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

switch = fn points, pi ->
  {prefix, [a, b | tail]} = Enum.split(points, pi) |> Api.debug()
  prefix ++ [b, a | tail]
end

apply = fn
  {points, action, pi} ->
    case action do
      "add" -> points ++ [lib.points.new]
      "del" -> List.delete_at(points, pi)
      "up" -> switch.(points, pi - 1)
      "down" -> switch.(points, pi)
    end

  {device, action} ->
    case action do
      "enable" -> Map.put(device, :status, :enabled)
      "disable" -> Map.put(device, :status, :disabled)
    end
end

parse = fn params, points ->
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{points: points})
end

points = fn devices ->
  for {id, device} <- devices do
    for point <- device.points do
      for name <- lib.points.names.(point.names) do
        key = "#{point.type}:#{name}"
        {"#{id}/#{key}", Adb.get("flex:modbus:point:#{key}", 0)}
      end
    end
  end
  |> List.flatten()
  |> Enum.into(%{})
end

points = fn devices ->
  for {id, device} <- devices do
    {id,
     for {point, pi} <- Enum.with_index(device.points) do
       names = lib.points.names.(point.names)

       [
         {pi, names},
         for name <- names do
           key = "#{point.type}:#{name}"
           {key, Adb.get("flex:modbus:point:#{key}", 0)}
         end
       ]
     end
     |> List.flatten()
     |> Enum.into(%{})}
  end
  |> Enum.into(%{})
end

handler = fn
  {:mount, socket, state} ->
    Bus.subscribe!("flex:modbus:points")
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:modbus:logs")
    logs = lib.shift.(tzoffset, logs)
    devices = Api.subget!("flex:modbus:devices")
    points = points.(devices)
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
    state = Map.put(state, :points, points)
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :ui, ui)
    state = if length(index) > 0, do: state, else: modal.(state)
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

  {:event, socket, state = %{modal: %{id: nil}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:insert", parse.(params, []))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id, input: %{points: points}}}, event = "modal:submit",
   params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:update", {id, parse.(params, points)})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:delete", id)
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:update", {id, apply.({devices[id], action})})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = modal.(state)
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = modal.({state, id, devices[id], false})
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:points", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = modal.({state, id, devices[id], true})
    {socket, state}

  {:event, socket, state = %{modal: %{input: %{points: points}}},
   event = "click:point:" <> action, params = %{"pi" => pi}} ->
    Api.trace(view: path, event: event, params: params)
    pi = String.to_integer(pi)
    points = apply.({points, action, pi}) |> Api.warn()
    state = put_in(state, [:modal, :input, :points], points)
    {socket, state}

  {:event, socket, state = %{modal: %{input: %{points: points}}}, event = "modal:points:change",
   params} ->
    Api.trace(view: path, event: event, params: params)
    slave = params["slave"] |> Enum.map(lib.points.toint?)
    address = params["address"] |> Enum.map(lib.points.toint?)
    type = params["type"]
    names = params["names"]

    {points, _, _, _, _} =
      for _ <- points, reduce: {[], slave, address, type, names} do
        {points, [s | slave], [a | address], [t | type], [n | names]} ->
          {[%{slave: s, address: a, type: t, names: n} | points], slave, address, type, names}
      end

    points = points |> Enum.reverse()
    state = put_in(state, [:modal, :input, :points], points)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id, input: device}}, event = "modal:points:submit",
   params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus:update", {id, device})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    Api.warn(state.modal)
    {socket, state}

  {:info, socket, state, event = {"flex:modbus:devices", _, devices}} ->
    Api.trace(view: path, info: event)
    points = points.(devices)
    index = index.(devices)
    devices = Enum.into(devices, %{})
    state = Map.put(state, :devices, devices)
    state = Map.put(state, :index, index)
    state = Map.put(state, :points, points)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:modbus:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, lib.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state = %{points: points}, event = {"flex:modbus:points", _, {id, values}}} ->
    Api.trace(view: path, info: event)
    points = Map.put(points, id, values)
    state = Map.put(state, :points, points)
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
