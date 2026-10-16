use Terminal.Live

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, page_title: "Form1")
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    render.(state)

  {:event, socket, state, _event, _params} ->
    {socket, state}

  {:info, socket, state, _event} ->
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view(path, handler)
