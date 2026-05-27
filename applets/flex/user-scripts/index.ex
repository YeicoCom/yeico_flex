defmodule Flex.UserScripts.Index do
  alias Flex.UserScripts.IUtils
  use Flex.Use.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="User Scripts">
      <div class="flex flex-col w-full h-full overflow-y-auto">
        <div class="p-2 flex gap-2">
          <.fui fun={&UI.link/1} phx-click="click:add"><div class="hero-plus"/>Add User Script</.fui>
          <div class="grow"/>
          <.fui fun={&UI.link/1} phx-click="click:compact">Compact</.fui>
        </div>
        <div :for={id <- @index} class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
          <% item = @items[id] %>
          <.fui fun={&UI.link/1} phx-click="click:edit" phx-value-id={id}>
            {item.name},{item.delay},{item.status}
          </.fui>
          <div class="flex gap-2">
            <.fui fun={&UI.link/1} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
            <.fui fun={&UI.link/1} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
            <.fui fun={&UI.link/1} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
            <.fui fun={&UI.href/1} href={"/flex/user-scripts/code?id=#{id}"}>Code</.fui>
            <div class="grow"></div>
            <.fui fun={&UI.link/1} phx-click="click:delete" phx-value-id={id} type="danger">Delete</.fui>
          </div>
          <% log = @logs[id] %>
          <div :if={item.status==:enabled and log} class={["font-mono",
            log.error? && "text-red-500",
            !log.error? && "text-neutral-500",
          ]}>{log.dt} {log.msg}</div>
        </div>
      </div>
    </.fui>
    <.fui fun={&UI.modal/1} :if={@modal} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
      <% %{item: item, opts: opts} = @modal %>
      <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4"
        phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <div>Name</div>
          <.fui fun={&UI.input/1} name="name" value={item.name} required id="modal_autofocus" phx-hook="AutoFocus" pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*$"/>
          <div>Delay</div>
          <.fui fun={&UI.input/1} name="delay" value={item.delay} type="number" step="1" min="0" max="65535" required/>
          <div>Status</div>
          <.fui fun={&UI.select/1} name="status" value={item.status} values={opts.status} required/>
        </div>
        <.fui fun={&UI.button/1} type="submit" class="col-span-2">Accept</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    idb = Keyword.fetch!(opts, :idb)
    cdb = Keyword.fetch!(opts, :cdb)
    path = Keyword.fetch!(opts, :path)

    fn
      {:mount, socket, state} ->
        tzoffset = socket.assigns.tzoffset || 0
        logs = Api.subget!("flex:user-scripts:logs")
        logs = Lg.shift(tzoffset, logs)
        items = Api.subget!("flex:user-scripts:items")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "User Scripts")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :index, IUtils.index(items))
        state = Map.put(state, :items, Enum.into(items, %{}))
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :logs, logs)
        state = Map.put(state, :modal, nil)
        state = Ln.init(socket, state)

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
        Bus.broadcast!("flex:user-scripts:insert", IUtils.parse(params))
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{modal: %{id: id}}, event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-scripts:update", {id, IUtils.parse(params)})
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-scripts:delete", id)
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:action",
       params = %{"id" => id, "action" => action}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-scripts:update", {id, IUtils.apply(items[id], action)})
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
        Db.compact(cdb)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state, event = {"flex:user-scripts:items", _, items}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :items, Enum.into(items, %{}))
        state = Map.put(state, :index, IUtils.index(items))
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:user-scripts:logs", _, logs}} ->
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
