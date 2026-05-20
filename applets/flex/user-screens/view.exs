defmodule Flex.UserScreens.View do
  alias Flex.UserScreens.IUtils
  alias Flex.UserScreens.DUtils
  use Flex.Live

  defp canvas(assigns) do
    ~H"""
    <div id="design_frame" class="grow relative" phx-hook="ScreenViewer">
      <%= if @enabled do %>
      <div :if={@size} id="design_port" class="design-port overflow-hidden">
        <div id="design_panel" class="design-panel text-white select-none text-base [&_*]:cursor-default leading-none"
          draggable="false" style={@screen.props.style}>
          <.fui :for={{id, item} <- @index} fun={&DUtils.item/1} id={id} {item} rt={@rts[id]} selected={false} runtime={true}/>
        </div>
      </div>
      <style :if={@size}>
        .design-port {
          position: absolute;
          left: <%= @port.x %>px;
          top: <%= @port.y %>px;
          width: <%= @port.w %>px;
          height: <%= @port.h %>px;
        }
        .design-panel {
          position: absolute;
          transform-origin: top left;
          scale: <%= @panel.s %>;
          left: <%= @panel.x %>px;
          top: <%= @panel.y %>px;
          width: <%= @panel.w %>px;
          height: <%= @panel.h %>px;
        }
      </style>
      <% else %>
      <div class="flex items-center h-full justify-center text-3xl">Disabled</div>
      <% end %>
    </div>
    <.fui fun={&UI.modal/1} :if={@modal} title={@modal.title} class="min-w-[360px]">
        <.fui fun={@modal.fun} {@modal.pass}/>
    </.fui>
    """
  end

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} reverse={!@modal} title="Screen Viewer" label={@name} class="flex gap-2">
      <.fui fun={&canvas/1} {assigns}/>
    </.fui>
    """
  end

  defp bare(assigns) do
    ~H"""
    <div id="main_frame" class="flex h-full" phx-hook="AllPages" phx-window-keydown="modal:close" phx-key="Escape">
      <.fui fun={&canvas/1} {assigns}/>
    </div>
    """
  end

  defp login(assigns) do
    ~H"""
    <div id="login_view" class="h-full flex flex-col gap-4 justify-center items-center" phx-hook="AllPages">
      <div class="text-3xl text-white">{@name}</div>
      <form id="login_form" phx-submit="submit:login" class="flex flex-col gap-4 items-center" phx-update="ignore" autocomplete="off">
        <.fui fun={&UI.input/1} name="password" type="password" required id="modal_autofocus" phx-hook="AutoFocus"/>
        <.fui fun={&UI.button/1} type="submit" class="hidden">Login</.fui>
      </form>
      <.fui fun={&UI.href/1} href="/">Home</.fui>
    </div>
    """
  end

  defp render(state = %{fid: fid, password: password}) do
    case {password, fid} do
      {nil, nil} -> view(state)
      {nil, _} -> bare(state)
      {_, _} -> login(state)
    end
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    fid = Keyword.fetch!(opts, :fid)
    ddb = Keyword.fetch!(opts, :ddb)

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Screen Viewer")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :enabled, nil)
        state = Map.put(state, :modal, nil)
        state = Map.put(state, :events, %{})
        state = Map.put(state, :size, nil)
        state = Map.put(state, :name, nil)
        state = Map.put(state, :rts, %{})
        state = Map.put(state, :fid, fid)
        state = Map.put(state, :id, nil)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        id = params["id"] || fid
        state = Map.put(state, :screen, DUtils.subget_screen(ddb, id))
        # it may not exist: use screen[:name] assessor
        screen = Api.subget!("flex:user-screens:item:#{id}")
        state = Map.put(state, :enabled, screen[:status] == :enabled)
        state = Map.put(state, :password, IUtils.password?(screen[:password]))
        state = Map.put(state, :name, screen[:name])
        state = Map.put(state, :id, id)

        state =
          for {id, item} <- state.screen.items, reduce: state do
            state -> DUtils.init(state, id, item, false)
          end

        {socket, state}

      {:render, _assigns,
       state = %{
         enabled: true,
         size: %{w: fw, h: fh},
         screen: %{items: items, props: %{w: sw, h: sh}}
       }} ->
        index = Enum.sort_by(items, fn {_, item} -> item.index end)
        state = Map.put(state, :index, index)
        port = %{s: s} = DUtils.port("All", fw, fh, sw, sh)
        panel = %{s: s, x: 0, y: 0, w: sw, h: sh}
        state = Map.put(state, :port, port)
        state = Map.put(state, :panel, panel)
        render(state)

      {:render, _assigns, state} ->
        render(state)

      {:event, socket, state, event = "item:click", params = %{"id" => "item_" <> id_type}} ->
        Log.trace(view: path, event: event, params: params)
        [id, _type] = String.split(id_type, "_")
        state = DUtils.handle(state, id, {:event, event, params})
        {socket, state}

      {:event, socket, state, event = "item:modal", params = %{"id" => "item_" <> id_type}} ->
        Log.trace(view: path, event: event, params: params)
        [id, _type] = String.split(id_type, "_")
        state = DUtils.handle(state, id, {:modal, event, params})
        {socket, state}

      {:event, socket, state, event = "submit:modal", params = %{"id" => id}} ->
        Log.trace(view: path, event: event, params: params)
        state = DUtils.handle(state, id, {:submit, event, params})
        {socket, state}

      {:event, socket, state, event = "hook:resize", params = %{"width" => w, "height" => h}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :size, %{w: w, h: h})
        {socket, state}

      {:event, socket, state = %{password: password}, event = "submit:login",
       params = %{"password" => password}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :password, nil)
        {socket, state}

      {:event, socket, state, event = "modal:close", params} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, _screen}} ->
        Log.trace(view: path, info: event)
        socket = push_event(socket, "hook:reload", %{})
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-screens:design:" <> id, _, _screen}} ->
        Log.trace(view: path, info: event)
        socket = push_event(socket, "hook:reload", %{})
        {socket, state}

      {:info, socket, state = %{events: events}, event = {"flex:point:" <> key, _, value}} ->
        Log.trace(view: path, info: event)
        ids = events[key] || []

        state =
          for id <- ids, reduce: state do
            state -> DUtils.handle(state, id, {:point, key, value})
          end

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
