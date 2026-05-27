defmodule Flex.Login do
  use Flex.Use.Live

  defp view(assigns) do
    ~H"""
    <div class="h-full flex flex-col gap-4 justify-center items-center">
      <image src="/applets/logo.svg" class="h-20"/>
      <div class="text-3xl text-white">Flex Login</div>
      <form id="login_view" phx-submit="submit:login" class="flex flex-col"
        phx-update="ignore" autocomplete="off" phx-hook="LoginView">
        <.fui fun={&UI.input/1} name="pass" type="password" required id="modal_autofocus" phx-hook="AutoFocus"
          class="text-center"/>
        <.fui fun={&UI.button/1} type="submit" class="hidden">Login</.fui>
      </form>
    </div>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)

    fn
      {:mount, socket = %{assigns: %{params: params}}, state} ->
        referer = Base.decode16!(params["to"] || "2F666C6578")
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Login")
        state = Map.put(state, :referer, referer)
        state = Ln.init(socket, state)
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
