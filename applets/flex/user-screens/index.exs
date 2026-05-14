defmodule Flex.UserScreens.Index do
  alias Flex.UserScreens.IUtils
  alias Flex.UserScreens.DUtils
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={@ui.frame} title="User Screens">
      <div class="flex flex-col w-full h-full overflow-y-auto">
        <div class="px-4 py-2 flex gap-2">
          <.fui fun={@ui.link} phx-click="click:add"><div class="hero-plus"/>Add User Screen</.fui>
          <div class="grow"/>
          <.fui fun={@ui.link} phx-click="click:paste">Paste</.fui>
          <.fui fun={@ui.link} phx-click="click:compact">Compact</.fui>
        </div>
        <div :for={id <- @index} class="flex flex-col p-2 hover:rounded hover:bg-zinc-800">
          <% item = @items[id] %>
          <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>
            {item.name},{item.route}
          </.fui>
          <div class="flex gap-2">
            <.fui fun={@ui.link} phx-click="click:edit" phx-value-id={id}>Edit</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="enable">Enable</.fui>
            <.fui fun={@ui.link} phx-click="click:action" phx-value-id={id} phx-value-action="disable">Disable</.fui>
            <.fui fun={@ui.href} href={"/flex/user-screens/design?id=#{id}"}>Design</.fui>
            <.fui fun={@ui.href} href={"/flex/user-screens/view?id=#{id}"}>View</.fui>
              <.fui fun={@ui.link} phx-click="click:copy" phx-value-id={id}>Copy</.fui>
              <div class="grow"/>
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
    <.fui fun={@ui.modal} :if={@modal[:type] == :edit} title={@modal.title} class="min-w-[360px] flex flex-col gap-2">
      <% %{item: item, opts: opts} = @modal %>
      <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-4"
        phx-hook="EnterNavigation" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-[5em_1fr] gap-2 items-center min-w-[12em]">
          <div>Name</div>
          <.fui fun={@ui.input} name="name" value={item.name} required id="modal_autofocus" phx-hook="AutoFocus" pattern="^[ ]*[a-zA-Z]+[a-zA-Z0-9 ]*$"/>
          <div>Route</div>
          <%!-- macos ignores pattern for optional inputs --%>
          <.fui fun={@ui.input} name="route" value={item.route}/>
          <div>Password</div>
          <.fui fun={@ui.input} name="password" value={item.password} type="password"/>
          <div>Status</div>
          <.fui fun={@ui.select} name="status" value={item.status} values={opts.status} required/>
        </div>
        <.fui fun={@ui.button} type="submit" class="col-span-2">Accept</.fui>
      </form>
    </.fui>
    <.fui fun={@ui.modal} :if={@modal[:type] == :paste} title={@modal.title} class="min-w-[360px]">
      <form id="modal_form" phx-submit="modal:submit" class="flex flex-col gap-2"
        phx-update="ignore" autocomplete="off" phx-hook="EnterNavigation">
        <.fui fun={@ui.area} name="data" rows={12} class="text-xs" id="modal_autofocus" phx-hook="AutoFocus"/>
        <.fui fun={@ui.button} type="submit">Accept</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    idb = Keyword.fetch!(opts, :idb)
    ddb = Keyword.fetch!(opts, :ddb)
    path = Keyword.fetch!(opts, :path)
    ui = Keyword.fetch!(opts, :ui)

    fn
      {:mount, socket, state} ->
        tzoffset = socket.assigns.tzoffset || 0
        logs = Api.subget!("flex:user-screens:logs")
        logs = Lg.shift(tzoffset, logs)
        items = Api.subget!("flex:user-screens:items")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "User Screens")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :items, Enum.into(items, %{}))
        state = Map.put(state, :index, IUtils.index(items))
        state = Map.put(state, :logs, logs)
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
        Bus.broadcast!("flex:user-screens:insert", IUtils.parse(params))
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{modal: %{id: id}}, event = "modal:submit", params} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-screens:update", {id, IUtils.parse(params)})
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, event = "modal:submit", params = %{"data" => data}} ->
        Log.trace(view: path, event: event, params: params)

        with ["user-screen", hash, data64] <- String.split(data, ":"),
             ^hash <- :crypto.hash(:md5, data64) |> Base.encode16(),
             {:ok, code} <- Base.decode64(data64),
             {%{id: id, type: "user-screen", item: item, design: design}, _} <-
               Code.eval_string(code) do
          DUtils.save_screen(ddb, %{id: id, screen: design}, true)
          Bus.broadcast!("flex:user-screens:update", {id, item})
          state = Map.put(state, :modal, nil)
          {socket, state}
        else
          _ -> {socket, state}
        end

      {:event, socket, state = %{items: items}, event = "click:copy", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        type = "user-screen"
        item = %{items[id] | status: :disabled}
        payload = %{id: id, type: type, item: item, design: DUtils.load_screen(ddb, id)}
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
        Db.compact(ddb)
        {socket, state}

      {:event, socket, state, event = "click:delete", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-screens:delete", id)
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:action",
       params = %{"id" => id, "action" => action}} ->
        Log.trace(view: path, event: event, params: params)
        Bus.broadcast!("flex:user-screens:update", {id, IUtils.apply(items[id], action)})
        {socket, state}

      {:event, socket, state, event = "click:add", params} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:add, state})
        {socket, state}

      {:event, socket, state = %{items: items}, event = "click:edit", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = IUtils.modal({:edit, state, id, items[id]})
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state, event = {"flex:user-screens:items", _, items}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :items, Enum.into(items, %{}))
        state = Map.put(state, :index, IUtils.index(items))
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset}, event = {"flex:user-screens:logs", _, logs}} ->
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
