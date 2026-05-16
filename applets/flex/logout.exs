defmodule Flex.Logout do
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Logout">
      <div id="logout_view" phx-hook="LogoutView"/>
    </.fui>
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
        socket = assign(socket, page_title: "Logout")
        state = Map.put(state, :referer, referer)
        {socket, state}

      {:params, socket, state = %{referer: referer}, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        expiry = NaiveDateTime.add(NaiveDateTime.utc_now(), 2_000, :millisecond)
        token = Terminal.encode(%{key: "user", value: nil, expiry: expiry, redirect: referer})
        query = URI.encode_query(%{token: token})
        socket = push_event(socket, "session:destroy", %{put: "/put?#{query}"})
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

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
