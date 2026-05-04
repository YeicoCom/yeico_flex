use Terminal.Live

view = fn assigns ->
  ~H"""
  <.fui fun={@ui.frame} reverse={true} title="Screen Viewer" label={@name} class="flex gap-2">
    <div  id="design_frame" class="grow relative" phx-hook="ScreenViewer">
      <%= if @enabled do %>
      <div :if={@size} id="design_port" class="design-port overflow-hidden">
        <div id="design_panel" class="design-panel text-white select-none text-base [&_*]:cursor-default leading-none"
          draggable="false" style={@screen.props.style}>
          <.fui :for={{id, item} <- @index} fun={@dutils.item} id={id} {item} rt={@rts[id]} selected={false} runtime={true}/>
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
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex.css")
    socket = assign(socket, applet_js: "/applets/flex.js")
    socket = assign(socket, page_title: "Screen Viewer")
    socket = assign(socket, page_suffix: " · Flex")
    state = Map.put(state, :dutils, dutils)
    state = Map.put(state, :enabled, nil)
    state = Map.put(state, :events, %{})
    state = Map.put(state, :size, nil)
    state = Map.put(state, :name, nil)
    state = Map.put(state, :rts, %{})
    state = Map.put(state, :id, nil)
    state = Map.put(state, :ui, ui)
    {socket, state}

  {:params, socket, state, params = %{"id" => id}, uri} ->
    Api.trace(view: path, params: params, uri: uri)
    screen = Api.subget!("flex:user-screens:design:#{id}")
    state = Map.put(state, :screen, screen || dutils.load.(id))
    # it may not exist: use screen[:name] accesor
    screen = Api.subget!("flex:user-screens:item:#{id}")
    state = Map.put(state, :enabled, screen[:status] == :enabled)
    state = Map.put(state, :name, screen[:name])
    state = Map.put(state, :id, id)

    state =
      for {id, item} <- state.screen.items, reduce: state do
        state -> dutils.init.(state, id, item, false)
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
    port = %{s: s} = dutils.port.("All", fw, fh, sw, sh)
    panel = %{s: s, x: 0, y: 0, w: sw, h: sh}
    state = Map.put(state, :port, port)
    state = Map.put(state, :panel, panel)
    view.(state)

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "item:click", params = %{"id" => "item_" <> id_type}} ->
    Api.trace(view: path, event: event, params: params)
    [id, _type] = String.split(id_type, "_")
    state = dutils.handle.(state, id, event)
    {socket, state}

  {:event, socket, state, event = "hook:resize", params = %{"width" => w, "height" => h}} ->
    Api.trace(view: path, event: event, params: params)
    state = Map.put(state, :size, %{w: w, h: h})
    {socket, state}

  {:event, socket, state, event, params} ->
    Api.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-screens:item:" <> id, _, _screen}} ->
    Api.trace(view: path, info: event)
    socket = push_event(socket, "hook:reload", %{})
    {socket, state}

  {:info, socket, state = %{id: id}, event = {"flex:user-screens:design:" <> id, _, _screen}} ->
    Api.trace(view: path, info: event)
    socket = push_event(socket, "hook:reload", %{})
    {socket, state}

  {:info, socket, state = %{events: events}, event = {key, _, value}} ->
    Api.trace(view: path, info: event)
    ids = events[key] || []

    state =
      for id <- ids, reduce: state do
        state -> dutils.handle.(state, id, {key, value})
      end

    {socket, state}

  {:info, socket, state, event} ->
    Api.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Api.trace(view: path, close: reason)
    :ok
end

:ok
