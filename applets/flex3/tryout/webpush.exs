use Terminal.Live

webpush_config = Api.path("secret/vapid.json") |> File.read!() |> Jason.decode!()

webpush_vars = [
  {"WEBPUSH_PUBKEY", webpush_config["publicKey"]},
  {"WEBPUSH_PRIVKEY", webpush_config["privateKey"]}
]

pubkey = webpush_config["publicKey"]

{runexs, _} = Api.evalf("flex3/runexs.exs")
Api.async(fn -> runexs.({"flex3/backends/webpush.exs", name: "webpush", env: webpush_vars}) end)
node = "webpush@#{Api.hostname()}.local" |> String.to_atom()

pusher = fn
  {:all, title, color} ->
    msg = %{title: title, options: %{icon: "/applets/flex3/#{color}.png"}}
    send({:webpush, node}, {:all, msg})

  {:one, sub, title} ->
    msg = %{title: title, options: %{icon: "/applets/flex3/gray.png"}}
    send({:webpush, node}, {:one, sub, msg})

  message ->
    send({:webpush, node}, message)
end

view = fn assigns ->
  ~H"""
  <div id="main-view" data-theme="light" phx-hook="WebPush"
    class="flex flex-col h-screen items-center justify-center bg-base-100 text-base-content">
    <div id="main-panel" class="flex flex-col px-8 py-4 gap-4">
      <button phx-click="click:test" disabled={!@backend} class="daisy-btn daisy-btn-neutral">Test Notification</button>
      <button phx-click="click:enable" disabled={!@backend} class="daisy-btn daisy-btn-neutral">Enable Notification</button>
      <button phx-click="click:disable" disabled={!@backend} class="daisy-btn daisy-btn-neutral">Disable Notification</button>
    </div>
  </div>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, applet_args: %{static: "/applets/flex3"})
    socket = assign(socket, page_title: "WebPush")
    state = Map.put(state, :backend, Api.subget!("backend:webpush"))
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "hook:webpush", params} ->
    Log.trace(event: path, event: event, params: params)
    pusher.({:add, params})
    state = Map.put(state, :sub, params)
    {socket, state}

  {:event, socket, state = %{sub: sub}, event = "click:test", params} ->
    Log.trace(event: path, event: event, params: params)
    pusher.({:one, sub, "Testing 1,2,3"})
    {socket, state}

  {:event, socket, state, event = "click:enable", params} ->
    Log.trace(event: path, event: event, params: params)
    socket = push_event(socket, "enable_webpush", %{pubkey: pubkey})
    {socket, state}

  {:event, socket, state = %{sub: sub}, event = "click:disable", params} ->
    Log.trace(event: path, event: event, params: params)
    socket = push_event(socket, "disable_webpush", %{})
    state = Map.put(state, :sub, nil)
    if sub, do: pusher.({:del, sub})
    {socket, state}

  {:event, socket, state, event, params} ->
    Log.trace(event: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"backend:webpush", _, value}} ->
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
