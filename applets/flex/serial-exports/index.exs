defmodule Flex.SerialExports.Index do
  alias Flex.SerialExports.IUtils
  use Flex.Live

  def view(assigns) do
    ~H"""
    <.fui fun={@ui.frame} title="Serial Exports">
      <div class="flex flex-col w-full h-full overflow-y-auto">
        <div class="p-2 flex gap-2">
          <.fui fun={@ui.link} phx-click="click:add"><div class="hero-plus"/>Add Serial Export</.fui>
          <div class="grow"/>
          <.fui fun={@ui.link} phx-click="click:compact">Compact</.fui>
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

  def handler(opts) do
    idb = Keyword.fetch!(opts, :idb)
    path = Keyword.fetch!(opts, :path)
    ui = Keyword.fetch!(opts, :ui)

    fn
      {:mount, socket, state} ->
        tzoffset = socket.assigns.tzoffset || 0
        logs = Api.subget!("flex:serial-exports:logs")
        items = Api.subget!("flex:serial-exports:items")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Serial Exports")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :logs, Lg.shift(tzoffset, logs))
        state = Map.put(state, :index, IUtils.index(items))
        state = Map.put(state, :items, Enum.into(items, %{}))
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :modal, nil)
        state = Ln.init(socket, state)
        state = Map.put(state, :ui, ui)

        case length(state.index) > 0 do
          false -> {socket, IUtils.modal({:add, state})}
          true -> {socket, state}
        end

      {:params, socket, state = %{login?: true, user: nil}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        socket = Ln.forward(socket, path, uri)
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

      {:event, socket, state = %{modal: %{id: nil}}, event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:serial-exports:insert", IUtils.parse(params))
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{modal: %{id: id}}, event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:serial-exports:update", {id, IUtils.parse(params)})
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:serial-exports:delete", id)
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:action",
       params = %{"id" => id, "action" => action}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:serial-exports:update", {id, IUtils.apply(items[id], action)})
        {socket, state}

      {:event, socket, state, event = "click:add", params} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:add, state})
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:edit", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:edit, state, id, items[id]})
        {socket, state}

      {:event, socket, state, event = "click:compact", params} ->
        Log.trace(view: path, event: event, params: params)
        Db.compact(idb)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state, event = {"flex:serial-exports:items", _, items}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :index, IUtils.index(items))
        state = Map.put(state, :items, Enum.into(items, %{}))
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset},
       event = {"flex:serial-exports:logs", _, logs}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :logs, Lg.shift(tzoffset, logs))
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
