defmodule Flex.Login do
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={@ui.frame} title="Login" class="h-full flex flex-col justify-center items-center">
      <form id="login_view" phx-submit="submit:login" class="grid grid-cols-[1fr_6em] gap-2"
        phx-update="ignore" autocomplete="off" phx-hook="LoginView">
        <.fui fun={@ui.input} name="pass" type="password" required id="modal_autofocus" phx-hook="AutoFocus"/>
        <.fui fun={@ui.button} type="submit">Login</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    ui = Keyword.fetch!(opts, :ui)

    fn
      {:mount, socket = %{assigns: %{params: params}}, state} ->
        referer = Base.decode16!(params["to"] || "2F666C6578")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Login")
        state = Map.put(state, :referer, referer)
        state = Ln.init(socket, state)
        state = Map.put(state, :ui, ui)
        {socket, state}

      {:params, socket, state = %{referer: referer, user: %{name: "admin"}}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        socket = redirect(socket, to: referer)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, event = "submit:login", params = %{"pass" => pass}} ->
        Log.trace(view: path, event: event, params: params)
        socket = Ln.login(socket, state, pass)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
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
