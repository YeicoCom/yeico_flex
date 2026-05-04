use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} title="Generic Items">
    <div class="flex flex-col w-full h-full overflow-y-auto">
      <div class="p-2 flex">
        <.fui fun={@ui.link} phx-click="click:add">
        <div class="hero-plus"/>Add Generic Item
        </.fui>
        <div class="grow"/>
      </div>
      <div :for={id <- @index} class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
        <% item = @items[id] %>
        <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
          {item.name}
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
      <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
        <div>Name</div>
        <.fui fun={@ui.input} name="name" value={item.name} required id="modal_autofocus" phx-hook="AutoFocus"/>
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
    logs = Api.subget!("flex:generic-items:logs")
    logs = lib.shift.(tzoffset, logs)
    items = Api.subget!("flex:generic-items:items")
    index = lib.index.(items)
    items = Enum.into(items, %{})
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Generic Items")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :ui, libUserInterface)
    state = Map.put(state, :tzoffset, tzoffset)
    state = Map.put(state, :items, items)
    state = Map.put(state, :index, index)
    state = Map.put(state, :logs, logs)
    state = Map.put(state, :modal, nil)

    case length(index) > 0 do
      false -> {socket, lib.modal.({:add, state})}
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
    Bus.broadcast!("flex:generic-items:insert", lib.parse.(params))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{modal: %{id: id}}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:generic-items:update", {id, lib.parse.(params)})
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:generic-items:delete", id)
    {socket, state}

  {:event, socket, state = %{items: items}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:generic-items:update", {id, lib.apply.(items[id], action)})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = lib.modal.({:add, state})
    {socket, state}

  {:event, socket, state = %{items: items}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = lib.modal.({:edit, state, id, items[id]})
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"flex:generic-items:items", _, items}} ->
    Api.trace(view: path, info: event)
    index = lib.index.(items)
    items = Enum.into(items, %{})
    state = Map.put(state, :items, items)
    state = Map.put(state, :index, index)
    {socket, state}

  {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:generic-items:logs", _, logs}} ->
    Api.trace(view: path, info: event)
    state = Map.put(state, :logs, lib.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

:ok
