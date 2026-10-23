use Terminal.Live

path = "/"
mail = Flex.Mail.build()

Flex.BackendExs.new()
|> Flex.BackendExs.set(route: "flex3/backends/mail.exs")
|> Flex.BackendExs.set(name: mail.name)
|> Flex.BackendExs.set(env: mail.env)
|> Flex.BackendExs.run(rdms: 1000)

view = fn assigns ->
  ~H"""
  <div id="main-view"
    class="flex flex-col h-screen items-center justify-center bg-base-100 text-base-content">
    <div id="main-panel" class="flex flex-col px-8 py-4 gap-4">
      <button phx-click="click:send" disabled={!@backend} class="daisy-btn daisy-btn-outline">Send</button>
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
    socket = assign(socket, page_title: "Mail")
    state = Map.put(state, :backend, Api.subget!("backend:mail"))
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, event = "click:send", params} ->
    Log.trace(event: path, event: event, params: params)

    mail.sender.(%{
      from: "flex@yeico.com",
      to: "server@yeico.com",
      subject: "Flex Mail Tryout Subject",
      body: "Flex Mail Tryout Body"
    })

    {socket, state}

  {:event, socket, state, event, params} ->
    Log.trace(event: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"backend:mail", _, value}} ->
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
