use Terminal.Live

path = "/"
vapid = Flex.Vapid.build()

Flex.BackendExs.new()
|> Flex.BackendExs.set(route: "flex3/backends/vapid.exs")
|> Flex.BackendExs.set(name: vapid.name)
|> Flex.BackendExs.set(env: vapid.vars)
|> Flex.BackendExs.run()

view = fn assigns ->
  ~H"""
  <div id="main-view" phx-hook="Vapid"
    class="flex flex-col h-screen items-center justify-center bg-base-100 text-base-content">
    <div id="main-panel" class="flex flex-col px-8 py-4 gap-4">
      <button phx-click="click:test" disabled={!@backend} class="daisy-btn daisy-btn-outline">Test Notification</button>
      <button phx-click="click:enable" disabled={!@backend} class="daisy-btn daisy-btn-outline">Enable Notification</button>
      <button phx-click="click:disable" disabled={!@backend} class="daisy-btn daisy-btn-outline">Disable Notification</button>
    </div>
  </div>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, applet_args: %{static: "/applets/flex3"})
    socket = assign(socket, page_suffix: " · Flex")
    socket = assign(socket, page_title: "Vapid")
    state = Map.put(state, :backend, Api.subget!("backend:vapid"))
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "hook:vapid", params} ->
    Log.trace(event: path, event: event, params: params)
    vapid.pusher.({:add, params})
    state = Map.put(state, :sub, params)
    {socket, state}

  {:event, socket, state = %{sub: sub}, event = "click:test", params} ->
    Log.trace(event: path, event: event, params: params)
    vapid.pusher.({:one, sub, "Testing 1,2,3", "gray"})
    {socket, state}

  {:event, socket, state, event = "click:enable", params} ->
    Log.trace(event: path, event: event, params: params)
    socket = push_event(socket, "vapid:enable", %{pubkey: vapid.pubkey})
    {socket, state}

  {:event, socket, state = %{sub: sub}, event = "click:disable", params} ->
    Log.trace(event: path, event: event, params: params)
    socket = push_event(socket, "vapid:disable", %{})
    state = Map.put(state, :sub, nil)
    if sub, do: vapid.pusher.({:del, sub})
    {socket, state}

  {:event, socket, state, event, params} ->
    Log.trace(event: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"backend:vapid", _, value}} ->
    Log.trace(view: path, info: event)
    state = Map.put(state, :backend, value)
    {socket, state}

  {:info, socket, state, event} ->
    Log.trace(info: path, event: event)
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view(path, handler)
