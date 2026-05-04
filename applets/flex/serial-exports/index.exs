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
        <% item = @items[id] %>
        <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
          {item.tty},{item.bauds}@{item.bits},{item.ip}:{item.port},{item.status}
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
        <div :if={item.status==:enabled and log} class={[
          log.error? && "text-red-500",
          !log.error? && "text-neutral-500",
        ]}>{log.dt} {log.msg}</div>
      </div>
    </div>
  </.fui>
  <.fui fun={@ui.modal} :if={@modal} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
    <% %{item: item, opts: opts} = @modal %>
    <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4"
      phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
      <.fui fun={@ui.select} name="tty" value={item.tty} values={opts.ttys} class="min-w-[120px] overflow-x-auto" size="4" required
        id="modal_autofocus" phx-hook="AutoFocus"/>
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Bauds</div>
        <.fui fun={@ui.select} name="bauds" value={item.bauds} values={opts.bauds} required/>
        <div>Bits</div>
        <.fui fun={@ui.select} name="bits" value={item.bits} values={opts.bits} required/>
        <div>IP</div>
        <.fui fun={@ui.select} name="ip" value={item.ip} values={opts.ips} required/>
        <div>Port</div>
        <.fui fun={@ui.input} name="port" value={item.port} type="number" step="1" min="1024" max="65535" required/>
        <div>Status</div>
        <.fui fun={@ui.select} name="status" value={item.status} values={opts.status} required/>
      </div>
      <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
    </form>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:serial-exports:logs")
    logs = iutils.shift.(tzoffset, logs)
    items = Api.subget!("flex:serial-exports:items")
    index = iutils.index.(items)
    items = Enum.into(items, %{})
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Serial Exports")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :items, items)
    state = Map.put(state, :index, index)
    state = Map.put(state, :logs, logs)
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :ui, ui)

    case length(index) > 0 do
      false -> {socket, iutils.modal.({:add, state})}
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

  {:event, socket, state = %{modal: %{id: nil}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial-exports:insert", iutils.parse.(params))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial-exports:update", {id, iutils.parse.(params)})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial-exports:delete", id)
    {socket, state}

  {:event, socket, state = %{items: items}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial-exports:update", {id, iutils.apply.(items[id], action)})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = iutils.modal.({:add, state})
    {socket, state}

  {:event, socket, state = %{items: items}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = iutils.modal.({:edit, state, id, items[id]})
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:serial-exports:items", _, items}} ->
    Api.trace(view: path, info: event)
    index = iutils.index.(items)
    items = Enum.into(items, %{})
    state = Map.put(state, :items, items)
    state = Map.put(state, :index, index)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:serial-exports:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, iutils.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

:ok
