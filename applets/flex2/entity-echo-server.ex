defmodule Flex2.EchoServer do
  use Flex2.Entity
  alias Applet.Api.Tcp

  defp initial() do
    %{
      ip: "127.0.0.1",
      port: 0
    }
  end

  defp checks() do
    %{
      port: {:integer, 0, 65_535},
      ip: {:in, ["127.0.0.1", "0.0.0.0"]}
    }
  end

  defp start(%{port: port, ip: ip}, _) do
    {:ok, socket} = Tcp.listen(ip, port, active: true)
    Log.info("#{ip}:#{socket.port}")
    accept(socket)
  end

  defp clean(_, _) do
    :nop
  end

  defp accept(socket = %{port: port}) do
    Utils.flush()
    {:ok, conn} = Tcp.accept(socket)
    cid = "#{port}:#{conn.peer.ip}:#{conn.peer.port}"
    Log.info("#{cid} accepted")
    tag = "echo:client:#{port}:#{cid}"
    conn = Map.put(conn, :cid, cid)
    task = Async.spawn(tag, &handle/1, conn)
    Tcp.owner(conn, task)
    accept(socket)
  end

  defp handle(conn = %{socket: socket, cid: cid}) do
    receive do
      {:tcp, ^socket, data} ->
        :ok = Tcp.write(conn, data)
        handle(conn)

      {:tcp_closed, ^socket} ->
        Log.debug("#{cid} closed")

      unexpected ->
        Log.debug("#{cid} unexpected #{Log.inspect?(unexpected)}")
        # this kills and restarts the server as well
        exit(:kill)
    end
  end
end
