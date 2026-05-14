defmodule Flex.Ln do
  use Flex.Live

  def init(%{assigns: %{session: session}}, state) do
    state = Map.put(state, :login?, !!Terminal.rconfig("pass"))
    state = Map.put(state, :user, session["user"])
    state
  end

  def forward(socket, path, uri) do
    query = URI.parse(uri).query
    to = Base.encode16(if(query, do: "#{path}?#{query}", else: path))
    redirect(socket, to: "/flex/login?to=#{to}")
  end

  def login(socket, state, pass) do
    case Terminal.rconfig("pass") do
      ^pass -> login(socket, state)
      _ -> socket
    end
  end

  defp login(socket, %{referer: referer}) do
    user = %{name: "admin", ts: System.os_time(:second)}
    expiry = NaiveDateTime.add(NaiveDateTime.utc_now(), 1_000, :millisecond)
    token = Terminal.encode(%{key: "user", value: user, expiry: expiry, redirect: referer})
    query = URI.encode_query(%{token: token})
    push_event(socket, "session:create", %{put: "/put?#{query}", user: user})
  end
end

:ok
