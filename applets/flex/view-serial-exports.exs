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

new_modal = fn state ->
  options = serial.options
  options = Map.put(options, :ttys, serial.list.())
  modal = %{title: "New Serial Export", input: serial.new}
  state = Map.put(state, :modal, modal)
  Map.put(state, :options, options)
end

edit_modal = fn state, id, export = %{tty: tty} ->
  options = serial.options
  ttys = [tty | serial.list.()] |> Enum.uniq()
  options = Map.put(options, :ttys, ttys)
  modal = %{title: "Edit Serial Export", input: export}
  state = Map.put(state, :modal, modal)
  state = Map.put(state, :id, id)
  Map.put(state, :options, options)
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

apply = fn export, action ->
  case action do
    "enable" -> Map.put(export, :status, :enabled)
    "disable" -> Map.put(export, :status, :disabled)
    "local" -> Map.put(export, :ip, "127.0.0.1")
    "remote" -> Map.put(export, :ip, "0.0.0.0")
  end
end

parse = fn params ->
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "bauds", &String.to_integer/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{})
end

handler = fn
  {:mount, socket, state} ->
    tzoffset = socket.assigns.tzoffset || 0
    logs = Api.subget!("flex:serial:logs")
    logs = serial.shift.(tzoffset, logs)
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
    Bus.broadcast!("flex:serial:insert", parse.(params))
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{id: id}, event = "modal:submit", params} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial:update", {id, parse.(params)})
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :id, nil)
    {socket, state}

  {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial:delete", id)
    {socket, state}

  {:event, socket, state = %{exports: exports}, event = "click:action",
   params = %{"id" => id, "action" => action}} ->
    Api.trace(view: path, event: event, params: params)
    Bus.broadcast!("flex:serial:update", {id, apply.(exports[id], action)})
    {socket, state}

  {:event, socket, state, event = "click:add", params} ->
    Api.trace(view: path, event: event, params: params)
    state = new_modal.(state)
    {socket, state}

  {:event, socket, state = %{exports: exports}, event = "click:edit", params = %{"id" => id}} ->
    Api.trace(view: path, event: event, params: params)
    state = edit_modal.(state, id, exports[id])
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
    state = Map.put(state, :logs, serial.shift.(tzoffset, logs))
    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler)
