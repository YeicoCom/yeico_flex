use Flex.Backend

config = """
import Config

config :web_push_elixir,
  vapid_public_key: System.get_env("VAPID_PUBKEY"),
  vapid_private_key: System.get_env("VAPID_PRIVKEY"),
  vapid_subject: "mailto:flex@yeico.com"
"""

Config.Reader.eval!("config.exs", config) |> Application.put_all_env()

# https://github.com/elixir-lang/elixir/issues/13326 Waiting for lock on the build directory
# __ENV__.file -> ~/yeico_flex/applets/flex3/backends/vapid.exs
Mix.install([{:jason, "1.4.4"}, {:web_push_elixir, "0.4.0"}, {:exqlite, "0.33.1"}],
  system_env: %{ID: "#{__ENV__.file}/#{Api.name()}"}
)

{:ok, conn} = Exqlite.Basic.open(Api.fpath("@home/flex3_vapid.db") |> Log.debug())

{:ok, _, _, _} =
  Exqlite.Basic.exec(conn, "create table if not exists subs (sub text primary key)")

true = Process.register(self(), :vapid)

add = fn sub ->
  sub = Jason.encode!(sub)
  {:ok, _, _, _} = Exqlite.Basic.exec(conn, "insert or ignore into subs (sub) values (?1)", [sub])
end

del = fn sub ->
  sub = Jason.encode!(sub)
  {:ok, _, _, _} = Exqlite.Basic.exec(conn, "delete from subs where sub = (?1)", [sub])
end

push = fn sub, msg ->
  try do
    msg = Jason.encode!(msg)

    with false <- is_nil(sub),
         jsub <- Jason.encode!(sub),
         {:ok, %{status_code: 410}} <- WebPushElixir.send_notification(jsub, msg) do
      del.(sub)
    end
  rescue
    error -> IO.inspect(error: error, stack: __STACKTRACE__)
  catch
    error -> IO.inspect(error: error, stack: __STACKTRACE__)
  end
end

broad = fn msg ->
  with {:ok, _, %{rows: rows}, _} <- Exqlite.Basic.exec(conn, "select sub from subs") do
    for row <- rows do
      sub = Jason.decode!(row)
      spawn(fn -> push.(sub, msg) end)
    end
  end
end

loop = fn loop ->
  receive do
    {:ping, pid} -> send(pid, :pong)
    {:add, sub} -> spawn(fn -> add.(sub) end)
    {:del, sub} -> spawn(fn -> del.(sub) end)
    {:all, msg} -> spawn(fn -> broad.(msg) end)
    {:one, sub, msg} -> spawn(fn -> push.(sub, msg) end)
    unexpected -> {:unexpected, unexpected} |> IO.inspect()
  end

  loop.(loop)
end

Api.putcast!("backend:#{Api.name()}", true)

loop.(loop)
