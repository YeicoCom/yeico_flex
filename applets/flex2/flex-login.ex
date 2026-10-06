defmodule Flex.Login do
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <div id="login_view" class="flex flex-col items-center justify-center h-screen gap-4" phx-hook="Redirect">
      <image src="/applets/logo.svg" class="h-20"/>
      <div class="text-3xl text-white">Flex Login</div>
      <form id="login_form" phx-submit="submit:login" class="flex flex-col"
        phx-update="ignore" autocomplete="off">
        <input name="pass" type="password" required id="modal_autofocus" phx-hook="AutoFocus"
          class="text-center text-base leading-none border-0 rounded-lg ring-1 bg-zinc-600 text-neutral-200 outline-none focus:ring-lime-500"/>
        <button type="submit" class="hidden">Login</button>
      </form>
    </div>
    """
  end

  def handler(_) do
    fn
      {:mount, socket = %{assigns: %{params: params}}, state} ->
        referer = Base.decode16!(params["to"] || "2F666C657832")
        socket = assign(socket, applet_css: "/applets/flex2.css")
        socket = assign(socket, applet_js: "/applets/flex2.js")
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Login")
        state = Map.put(state, :pass, Terminal.rconfig("pass") || "flex")
        state = Map.put(state, :referer, referer)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state = %{pass: pass, referer: referer}, "submit:login", %{"pass" => pass}} ->
        expiry = NaiveDateTime.add(NaiveDateTime.utc_now(), 5_000, :millisecond)
        token = Terminal.encode(%{key: "user", value: "admin", expiry: expiry, redirect: referer})
        query = URI.encode_query(%{token: token})
        socket = push_event(socket, "hook:redirect", %{href: "/put?#{query}"})
        {socket, state}

      {:event, socket, state, _event, _params} ->
        {socket, state}

      {:info, socket, state, _event} ->
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end
end
