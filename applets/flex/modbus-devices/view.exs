use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Modbus Devices">
    <div class="flex flex-col w-full h-full overflow-y-auto">
      <div class="px-4 py-2 flex">
        <.fui fun={@ui.link} phx-click="click:add"><div class="hero-plus"/>Add Modbus Device</.fui>
        <div class="grow"/>
        <.fui fun={@ui.link} phx-click="click:paste">Paste</.fui>
      </div>
      <div :for={id <- @index} class="flex flex-col p-2">
        <% device = @devices[id] %>
        <% values = @points.values %>
        <div class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
          <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
            {device.proto},{device.ip}:{device.port},{device.status},{device.delay},{device.name}
          </.fui>
          <div class="flex gap-2">
            <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
            <.fui fun={@ui.link} phx-click="click:points" phx-value-id={id}>Points</.fui>
            <.fui fun={@ui.link} phx-click="click:copy" phx-value-id={id}>Copy</.fui>
            <div class="grow"/>
            <.fui fun={@ui.link} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
          </div>
          <% log = @logs[id] %>
          <div :if={device.status==:enabled and log} class={[
            log.error? && "text-red-500",
            !log.error? && "text-neutral-500",
          ]}>{log.dt} {log.msg}</div>
        </div>
        <div class="flex flex-col p-1 gap-2 font-mono">
          <div :for={{%{type: type, slave: slave, address: address, encoding: encoding}, accessors} <- @points[id]}
            class="grid grid-cols-[12em_1fr] gap-1 hover:bg-zinc-800 rounded p-2">
            <div>{slave}:{address}:{type}:{encoding}</div>
            <div class="flex flex-col gap-1">
            <%= for %{name: name, key: key} <- accessors do %>
              <% val = values[key].val %>
              <% tval = if val>0, do: 0, else: 1 %>
              <%= cond do %>
              <% type in ["WDO"] -> %>
              <.fui fun={@ui.link} phx-click="click:putint" phx-value-key={key} phx-value-val={tval}
                title="Toggle">
                {name}:{val}
              </.fui>
              <% type in ["WRO"] -> %>
              <.fui fun={@ui.link} phx-click="click:capture" phx-value-key={key} phx-value-val={val}  phx-value-enc={encoding}
                title="Capture Value">
                {name}:{val}
              </.fui>
              <% true -> %>
              <div>{name}:{val}</div>
              <% end %>
            <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal[:type] == :device} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
    <% device = @modal.input %>
    <form id="modal_form" phx-submit="submit:device" class="flex flex-col gap-4"
      phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Name</div>
        <.fui fun={@ui.input} name="name" value={device.name} type="text" required id="modal_autofocus" phx-hook="AutoFocus" pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*$"/>
        <div>Protocol</div>
        <.fui fun={@ui.select} name="proto" value={device.proto} values={@options.protos} required/>
        <div>IP</div>
        <.fui fun={@ui.input} name="ip" value={device.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={device.port} type="number" step="1" min="1" max="65535" required/>
        <div>Delay</div>
        <.fui fun={@ui.input} name="delay" value={device.delay} type="number" step="1" min="0" max="65535" required/>
        <div>Status</div>
        <.fui fun={@ui.select} name="status" value={device.status} values={@options.status} required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal[:type] == :points} title={@modal.title}
    class="min-w-[360px] max-h-[80%] h-[80%] flex flex-col">
    <% device = @modal.input %>
    <div class="grow overflow-y-hidden">
      <form id="modal_form" phx-submit="submit:points" phx-change="change:points"
        class="h-full flex flex-col gap-1" phx-hook="EnterNavigation" autocomplete="off">
        <div>{device.proto},{device.ip}:{device.port},{device.status},{device.name}</div>
        <div class="grid grid-cols-[3em_4em_4em_5em_12em_1fr] md:grid-cols-[3em_4em_4em_5em_20em_1fr] lg:grid-cols-[3em_4em_4em_5em_32em_1fr] gap-1">
          <div>Slave</div>
          <div>Address</div>
          <div>Type</div>
          <div>Encoding</div>
          <div>Name(s)</div>
          <.fui fun={@ui.link} phx-click="click:point:add" phx-value-pi={0} title="Add Point"><div class="hero-plus z-0"/>Point</.fui>
        </div>
        <div class="grow overflow-y-scroll flex flex-col gap-1 p-1">
          <% pl = length(device.points) - 1 %>
          <%= for {point, pi} <- Enum.with_index(device.points) do %>
            <div class="grid grid-cols-[3em_4em_4em_5em_12em_1fr] md:grid-cols-[3em_4em_4em_5em_20em_1fr] lg:grid-cols-[3em_4em_4em_5em_32em_1fr] gap-1">
              <.fui fun={@ui.input} name="slave[]" value={point.slave} type="number" step="1" min="0" max="255" required/>
              <.fui fun={@ui.input} name="address[]" value={point.address} type="number" step="1" min="0" max="65535" required/>
              <.fui fun={@ui.select} name="type[]" value={point.type} values={@options.types} required/>
              <.fui fun={@ui.select} name="encoding[]" value={point.encoding} values={@options.encodings} required/>
              <%!-- Force name even for unused because they look ugly on the point table and require a placeholder anyway --%>
              <.fui fun={@ui.input} name="names[]" value={point.names} type="text" required pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*(,[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*)*$"/>
              <div class="flex gap-1">
                <.fui fun={@ui.link} disabled={pi==0} phx-click="click:point:del" phx-value-pi={pi} type="danger" title="Delete Point"><div class="hero-x-mark z-0"/></.fui>
                <.fui fun={@ui.link} disabled={pi==0} phx-click="click:point:up" phx-value-pi={pi} title="Move Point Up"><div class="hero-arrow-up z-0"/></.fui>
                <.fui fun={@ui.link} disabled={pi==pl} phx-click="click:point:down" phx-value-pi={pi} title="Move Point Down"><div class="hero-arrow-down z-0"/></.fui>
              </div>
            </div>
          <% end %>
        </div>
        <.fui fun={@ui.button} type="submit" class="mt-2">Accept</.fui>
      </form>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal[:type] == :capture} title={@modal.title} class="min-w-[360px]">
    <% %{key: key, val: val, enc: enc} = @modal.input %>
    <form id="modal_form" phx-submit="submit:capture" class="grid grid-cols-[1fr_6em] gap-2"
      phx-update="ignore" autocomplete="off">
      <input type="hidden" name="key" value={key}/>
      <.fui :if={enc in ["NONE", "U16BE", "U16LE"]} fun={@ui.input} name="val" value={val} type="number" step="1" min="0" max="65535" required id="modal_autofocus" phx-hook="AutoFocus"/>
      <.fui :if={enc in ["F32BE", "F32LE"]} fun={@ui.input} name="val" value={val} type="number" step="any" required id="modal_autofocus" phx-hook="AutoFocus"/>
      <.fui fun={@ui.button} type="submit">Accept</.fui>
    </form>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal[:type] == :paste} title={@modal.title} class="min-w-[360px]">
    <form id="modal_form" phx-submit="submit:paste" class="flex flex-col gap-2"
      phx-update="ignore" autocomplete="off" phx-hook="EnterNavigation">
      <.fui fun={@ui.area} name="data" rows={12} class="text-xs" id="modal_autofocus" phx-hook="AutoFocus"/>
      <.fui fun={@ui.button} type="submit">Accept</.fui>
    </form>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    refresh = 100
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:modbus-devices:logs")
    logs = dlib.shift.(tzoffset, logs)
    devices = Api.subget!("flex:modbus-devices:items")
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Modbus Devices")
    socket = assign(socket, page_suffix: " · Flex")
    state = dlib.runtime.(state, devices)
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :refresh, refresh)
    state = Map.put(state, :logs, logs)
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :ui, ui)
    # prevent events overwhelm
    Process.send_after(self(), :refresh, refresh)

    case length(state.index) > 0 do
      false -> {socket, dlib.modal.({:device, state})}
      true -> {socket, state}
    end

  {:params, socket, state, params, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{modal: %{id: nil}}, event = "submit:device", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus-devices:insert", dlib.parse.(params, []))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id, input: %{points: points}}}, event = "submit:device",
   params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus-devices:update", {id, dlib.parse.(params, points)})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "submit:paste", params = %{"data" => data}} ->
    Api.trace(view: path, event: event, params: params)

    with ["modbus-device", hash, data64] <- String.split(data, ":"),
         ^hash <- :crypto.hash(:md5, data64) |> Base.encode16(),
         {:ok, code} <- Base.decode64(data64),
         {%{id: id, type: "modbus-device", item: item}, _} <- Code.eval_string(code) do
      Bus.broadcast!("flex:modbus-devices:update", {id, item})
      state = Map.put(state, :modal, nil)
      {socket, state}
    else
      _ -> {socket, state}
    end

  {:event, socket, state = %{devices: devices}, event = "click:copy", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    type = "modbus-device"
    item = %{devices[id] | status: :disabled}
    payload = %{id: id, type: type, item: item}
    data64 = inspect(payload, limit: :infinity) |> Base.encode64()
    hash = :crypto.hash(:md5, data64) |> Base.encode16()
    socket = push_event(socket, "hook:copy", %{text: "#{type}:#{hash}:#{data64}"})
    {socket, state}

  {:event, socket, state, event = "click:paste", params} ->
    Api.trace(view: path, event: event, params: params)
    state = dlib.modal.({:paste, state})
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus-devices:delete", id)
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:modbus-devices:update", {id, plib.apply.({devices[id], action})})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = dlib.modal.({:device, state})
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = dlib.modal.({:device, state, id, devices[id]})
    {socket, state}

  {:event, socket, state = %{devices: devices}, event = "click:points", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = dlib.modal.({:points, state, id, devices[id]})
    {socket, state}

  {:event, socket, state = %{modal: %{input: %{points: points}}},
   event = "click:point:" <> action, params = %{"pi" => pi}} ->
    Api.trace(view: path, event: event, params: params)
    pi = String.to_integer(pi)
    points = plib.apply.({points, action, pi})
    state = put_in(state, [:modal, :input, :points], points)
    {socket, state}

  {:event, socket, state = %{modal: %{input: device}}, event = "change:points", params} ->
    Api.trace(view: path, event: event, params: params)
    device = plib.parse.(device, params)
    state = put_in(state, [:modal, :input], device)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id, input: device}}, event = "submit:points", params} ->
    Api.trace(view: path, event: event, params: params)
    device = plib.parse.(device, params)
    Bus.broadcast!("flex:modbus-devices:update", {id, device})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{points: %{values: values}}, event = "click:putint",
   params = %{"key" => key, "val" => val}} ->
    Api.trace(view: path, event: event, params: params)
    values[key].put.(String.to_integer(val))
    {socket, state}

  {:event, socket, state, event = "click:capture",
   params = %{"key" => key, "val" => val, "enc" => enc}} ->
    Api.trace(view: path, event: event, params: params)
    state = dlib.modal.({:capture, state, key, val, enc})
    {socket, state}

  {:event, socket, state = %{points: %{values: values}}, event = "submit:capture",
   params = %{"key" => key, "val" => val}} ->
    Api.trace(view: path, event: event, params: params)
    %{put: put, parse: parse} = values[key]
    [val] = parse.(val)
    put.(val)
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{refresh: refresh, points: points}, :refresh} ->
    # Api.trace(view: path, info: event)
    Process.send_after(self(), :refresh, refresh)
    state = Map.put(state, :points, dlib.values.(points))
    {socket, state}

  {:info, socket, state, event = {"flex:modbus-devices:items", _, devices}} ->
    Api.trace(view: path, info: event)
    state = dlib.runtime.(state, devices)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:modbus-devices:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, dlib.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
