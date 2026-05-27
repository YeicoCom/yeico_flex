defmodule Flex.ModbusDevices.Index do
  alias Flex.ModbusDevices.PUtils
  alias Flex.ModbusDevices.IUtils
  use Flex.Use.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Modbus Devices">
      <div class="flex flex-col w-full h-full overflow-y-auto">
        <div class="px-2 py-2 flex gap-2">
          <.fui fun={&UI.link/1} phx-click="click:add"><div class="hero-plus"/>Add Modbus Device</.fui>
          <div class="grow"/>
          <.fui fun={&UI.link/1} phx-click="click:paste">Paste</.fui>
          <.fui fun={&UI.link/1} phx-click="click:compact">Compact</.fui>
        </div>
        <div :for={id <- @index} class="flex flex-col p-2">
          <% item = @items[id] %>
          <% values = @points.values %>
          <div class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
            <.fui fun={&UI.link/1} phx-click="click:edit" phx-value-id={id}>
              {item.name},{item.proto},{item.ip}:{item.port},{item.delay},{item.status}
            </.fui>
            <div class="flex gap-2">
              <.fui fun={&UI.link/1} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
              <.fui fun={&UI.link/1} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
              <.fui fun={&UI.link/1} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
              <.fui fun={&UI.link/1} phx-click="click:points" phx-value-id={id}>Points</.fui>
              <.fui fun={&UI.link/1} phx-click="click:copy" phx-value-id={id}>Copy</.fui>
              <div class="grow"/>
              <.fui fun={&UI.link/1} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
            </div>
            <% log = @logs[id] %>
            <div :if={item.status==:enabled and log} class={["font-mono",
              log.error? && "text-red-500",
              !log.error? && "text-neutral-500",
            ]}>{log.dt} {log.msg}</div>
          </div>
          <div class="flex flex-col p-1 gap-2 font-mono">
            <div :for={{%{type: type, slave: slave, address: address, encoding: encoding}, accessors} <- @points[id]}
              class="grid grid-cols-[12em_1fr] gap-1 hover:bg-zinc-800 rounded p-2">
              <div>{slave}:{address}:{type}:{encoding}</div>
              <div class="flex flex-col gap-1">
              <%= cond do %>
              <% type in ["WDO"] -> %>
                <%= for %{name: name, key: key, tag: tag} <- accessors do %>
                <% val = values[key].val %>
                <% tval = if val>0, do: 0, else: 1 %>
                <div class="flex gap-1 px-1 rounded hover:bg-zinc-900">
                  <.fui fun={&UI.link/1} phx-click="click:capture" phx-value-key={key} phx-value-val={val}
                    phx-value-type={type} phx-value-enc={encoding} phx-value-tag={tag} title="Capture Value">
                    {name}:{val}
                  </.fui>
                  <div class="grow"/>
                  <.fui fun={&UI.link/1} phx-click="click:toggle" phx-value-key={key} phx-value-val={tval}
                    title="Toggle">
                    <div class="hero-arrows-right-left"/>
                  </.fui>
                </div>
                <% end %>
              <% type in ["WRO"] -> %>
                <%= for %{name: name, key: key, tag: tag} <- accessors do %>
                <% val = values[key].val %>
                <.fui fun={&UI.link/1} phx-click="click:capture" phx-value-key={key} phx-value-val={val}
                  phx-value-type={type} phx-value-enc={encoding} phx-value-tag={tag} title="Capture Value" class="px-1">
                  {name}:{val}
                </.fui>
                <% end %>
              <% true -> %>
                <%= for %{name: name, key: key} <- accessors do %>
                <% val = values[key].val %>
                <div class="px-1">{name}:{val}</div>
                <% end %>
              <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal[:type] == :item} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
      <% item = @modal.input %>
      <form id="modal_form" phx-submit="submit:item" class="flex flex-col gap-4"
        phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <div>Name</div>
          <.fui fun={&UI.input/1} name="name" value={item.name} type="text" required id="modal_autofocus" phx-hook="AutoFocus" pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*$"/>
          <div>Protocol</div>
          <.fui fun={&UI.select/1} name="proto" value={item.proto} values={@options.protos} required/>
          <div>IP</div>
          <.fui fun={&UI.input/1} name="ip" value={item.ip} type="text" required pattern="^(((?!25?[6-9])[12]\d|[1-9])?\d\.?\b){4}$"/>
          <div>Port</div>
          <.fui fun={&UI.input/1} name="port" value={item.port} type="number" step="1" min="1" max="65535" required/>
          <div>Delay</div>
          <.fui fun={&UI.input/1} name="delay" value={item.delay} type="number" step="1" min="0" max="65535" required/>
          <div>Status</div>
          <.fui fun={&UI.select/1} name="status" value={item.status} values={@options.status} required/>
        </div>
        <.fui fun={&UI.button/1} type="submit" class="col-span-2">Accept</.fui>
      </form>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal[:type] == :points} title={@modal.title}
      class="min-w-[360px] max-h-[80%] h-[80%] flex flex-col">
      <% item = @modal.input %>
      <div class="grow overflow-y-hidden">
        <form id="modal_form" phx-submit="submit:points" phx-change="change:points"
          class="h-full flex flex-col gap-1" phx-hook="EnterNavigation" autocomplete="off">
          <div>{item.name},{item.proto},{item.ip}:{item.port},{item.status}</div>
          <div class="grid grid-cols-[3em_4em_4em_5em_12em_1fr] md:grid-cols-[3em_4em_4em_5em_20em_1fr] lg:grid-cols-[3em_4em_4em_5em_32em_1fr] gap-1">
            <div>Slave</div>
            <div>Address</div>
            <div>Type</div>
            <div>Encoding</div>
            <div>Name(s)</div>
            <.fui fun={&UI.link/1} phx-click="click:point:add" phx-value-pi={0} title="Add Point"><div class="hero-plus"/>Point</.fui>
          </div>
          <div class="grow overflow-y-scroll flex flex-col gap-1 p-1">
            <% pl = length(item.points) - 1 %>
            <%= for {point, pi} <- Enum.with_index(item.points) do %>
              <div class="grid grid-cols-[3em_4em_4em_5em_12em_1fr] md:grid-cols-[3em_4em_4em_5em_20em_1fr] lg:grid-cols-[3em_4em_4em_5em_32em_1fr] gap-1">
                <.fui fun={&UI.input/1} name="slave[]" value={point.slave} type="number" step="1" min="0" max="255" required/>
                <.fui fun={&UI.input/1} name="address[]" value={point.address} type="number" step="1" min="0" max="65535" required/>
                <.fui fun={&UI.select/1} name="type[]" value={point.type} values={@options.types} required/>
                <.fui fun={&UI.select/1} name="encoding[]" value={point.encoding} values={@options.encodings} required/>
                <%!-- Force name even for unused because they look ugly on the point table and require a placeholder anyway --%>
                <.fui fun={&UI.input/1} name="names[]" value={point.names} type="text" required pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*(,[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*)*$"/>
                <div class="flex gap-1">
                  <.fui fun={&UI.link/1} disabled={pi==0} phx-click="click:point:del" phx-value-pi={pi} type="danger" title="Delete Point"><div class="hero-x-mark"/></.fui>
                  <.fui fun={&UI.link/1} disabled={pi==0} phx-click="click:point:up" phx-value-pi={pi} title="Move Point Up"><div class="hero-arrow-up"/></.fui>
                  <.fui fun={&UI.link/1} disabled={pi==pl} phx-click="click:point:down" phx-value-pi={pi} title="Move Point Down"><div class="hero-arrow-down"/></.fui>
                </div>
              </div>
            <% end %>
          </div>
          <.fui fun={&UI.button/1} type="submit" class="mt-2">Accept</.fui>
        </form>
      </div>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal[:type] == :capture} title={@modal.title} class="min-w-[360px]">
      <% %{step: step, min: min, max: max} = @modal.limits %>
      <% %{key: key, val: val} = @modal.input %>
      <form id="modal_form" phx-submit="submit:capture" class="grid grid-cols-[1fr_6em] gap-2"
        phx-update="ignore" autocomplete="off">
        <input type="hidden" name="key" value={key}/>
        <.fui fun={&UI.input/1} name="val" value={val} type="number" step={step} min={min} max={max} required id="modal_autofocus" phx-hook="AutoFocus"/>
        <.fui fun={&UI.button/1} type="submit">Accept</.fui>
      </form>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal[:type] == :paste} title={@modal.title} class="min-w-[360px]">
      <form id="modal_form" phx-submit="submit:paste" class="flex flex-col gap-2"
        phx-update="ignore" autocomplete="off" phx-hook="EnterNavigation">
        <.fui fun={&UI.area/1} name="data" rows={12} class="text-xs" id="modal_autofocus" phx-hook="AutoFocus"/>
        <.fui fun={&UI.button/1} type="submit">Accept</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    idb = Keyword.fetch!(opts, :idb)
    path = Keyword.fetch!(opts, :path)

    fn
      {:mount, socket, state} ->
        refresh = 100
        tzoffset = socket.assigns.tzoffset || 0
        logs = Api.subget!("flex:modbus-devices:logs")
        items = Api.subget!("flex:modbus-devices:items")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Modbus Devices")
        socket = assign(socket, page_suffix: " · Flex")
        state = IUtils.runtime(state, items)
        state = Map.put(state, :logs, Logs.shift(tzoffset, logs))
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :refresh, refresh)
        state = Map.put(state, :modal, nil)
        state = Login.init(socket, state)
        # prevent events overwhelm
        Process.send_after(self(), :refresh, refresh)

        case length(state.index) > 0 do
          false -> {socket, IUtils.modal({:item, state})}
          true -> {socket, state}
        end

      {:params, socket, state = %{login?: true, user: nil}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        socket = Login.forward(socket, path, uri)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, event = "modal:close", params} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{modal: %{id: nil}}, event = "submit:item", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:modbus-devices:insert", IUtils.parse(params, []))
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{modal: %{id: id, input: %{points: points}}},
       event = "submit:item", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:modbus-devices:update", {id, IUtils.parse(params, points)})
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, event = "submit:paste", params = %{"data" => data}} ->
        Log.trace(view: path, event: event, params: params)

        with ["modbus-item", hash, data64] <- String.split(data, ":"),
             ^hash <- :crypto.hash(:md5, data64) |> Base.encode16(),
             {:ok, code} <- Base.decode64(data64),
             {%{id: id, type: "modbus-item", item: item}, _} <- Code.eval_string(code) do
          Bus.broadcast!("flex:modbus-devices:update", {id, item})
          state = Map.put(state, :modal, nil)
          {socket, state}
        else
          _ -> {socket, state}
        end

      {:event, socket, state = %{items: items}, event = "click:copy", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        type = "modbus-item"
        item = %{items[id] | status: :disabled}
        payload = %{id: id, type: type, item: item}
        data64 = inspect(payload, limit: :infinity) |> Base.encode64()
        hash = :crypto.hash(:md5, data64) |> Base.encode16()
        socket = push_event(socket, "hook:copy", %{text: "#{type}:#{hash}:#{data64}"})
        {socket, state}

      {:event, socket, state, event = "click:paste", params} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:paste, state})
        {socket, state}

      {:event, socket, state, event = "click:compact", params} ->
        Log.trace(view: path, event: event, params: params)
        Db.compact(idb)
        {socket, state}

      {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:modbus-devices:delete", id)
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:action",
       params = %{"id" => id, "action" => action}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:modbus-devices:update", {id, PUtils.apply({items[id], action})})
        {socket, state}

      {:event, socket, state, event = "click:add", params} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:item, state})
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:edit", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:item, state, id, items[id]})
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:points", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:points, state, id, items[id]})
        {socket, state}

      {:event, socket, state = %{modal: %{input: %{points: points}}},
       event = "click:point:" <> action, params = %{"pi" => pi}} ->
        Log.trace(view: path, event: event, params: params)
        pi = String.to_integer(pi)
        points = PUtils.apply({points, action, pi})
        state = put_in(state, [:modal, :input, :points], points)
        {socket, state}

      {:event, socket, state = %{modal: %{input: item}}, event = "change:points", params} ->
        Log.trace(view: path, event: event, params: params)
        item = PUtils.parse(item, params)
        state = put_in(state, [:modal, :input], item)
        {socket, state}

      {:event, socket, state = %{modal: %{id: id, input: item}}, event = "submit:points", params} ->
        Log.trace(view: path, event: event, params: params)
        item = PUtils.parse(item, params)
        Bus.broadcast!("flex:modbus-devices:update", {id, item})
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{points: %{values: values}}, event = "click:toggle",
       params = %{"key" => key, "val" => val}} ->
        Log.trace(view: path, event: event, params: params)
        values[key].put.(String.to_integer(val))
        {socket, state}

      {:event, socket, state, event = "click:capture",
       params = %{"tag" => tag, "key" => key, "val" => val, "type" => type, "enc" => enc}} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:capture, state, key, val, type, enc, tag})
        {socket, state}

      {:event, socket, state = %{points: %{values: values}}, event = "submit:capture",
       params = %{"key" => key, "val" => val}} ->
        Log.trace(view: path, event: event, params: params)
        %{put: put, parse: parse} = values[key]
        [val] = parse.(val)
        put.(val)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{refresh: refresh, points: points}, :refresh} ->
        # Log.trace(view: path, info: event)
        Process.send_after(self(), :refresh, refresh)
        state = Map.put(state, :points, IUtils.values(points))
        {socket, state}

      {:info, socket, state, event = {"flex:modbus-devices:items", _, items}} ->
        Log.trace(view: path, info: event)
        state = IUtils.runtime(state, items)
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset},
       event = {"flex:modbus-devices:logs", _, logs}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :logs, Logs.shift(tzoffset, logs))
        {socket, state}

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
