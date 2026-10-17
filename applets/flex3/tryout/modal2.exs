use Terminal.Live

view = fn assigns ->
  ~H"""
  <div id="main_view" inert={!!@modal} phx-window-keydown="modal:close" phx-key="Escape"
    class="h-screen flex flex-col items-center justify-center">
    <button phx-click="modal:open" class="flex-button">Modal</button>
  </div>
  <.fui id="modal" fun={&Flex.Modal.render/1} :if={@modal} {@modal}>
    <div class="w-[400px] flex flex-col items-center justify-center">
      <button phx-click="modal:close" class="flex-button">
        Close Modal
      </button>
    </div>
  </.fui>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, page_title: "Modal2")
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state, "modal:open", _params} ->
    state = Map.put(state, :modal, %{title: "Modal"})
    {socket, state}

  {:event, socket, state, "modal:close", _params} ->
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, _event, _params} ->
    {socket, state}

  {:info, socket, state, _event} ->
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view(path, handler)
