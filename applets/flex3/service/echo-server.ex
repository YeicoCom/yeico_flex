defmodule Flex3.EchoServer do
  use Flex3.Service
  use Terminal

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

  defp name(%{port: port, ip: ip}) do
    "echo-server:#{port}:#{ip}"
  end

  defp setup(%{port: port, ip: ip}) do
    {:ok, socket = %{port: port}} = Tcp.listen(ip, port, active: true)
    clean(fn -> Tcp.close(socket) end)
    sid = "echo-server:#{port}:#{ip}"
    Log.debug("#{sid} started")
    accept(socket)
  end

  defp accept(socket = %{port: port}) do
    Api.flush(toms: 0)
    {:ok, conn = %{peer: peer}} = Tcp.accept(socket)
    cid = "echo-server:#{port}:#{peer.ip}:#{peer.port}"
    Log.trace("#{cid} accepted")
    conn = Map.put(conn, :cid, cid)
    task = Api.async(&handle/1, conn, tag: cid)
    Tcp.owner(conn, task)
    accept(socket)
  end

  defp handle(conn = %{socket: socket, cid: cid}) do
    receive do
      {:tcp, ^socket, data} ->
        :ok = Tcp.write(conn, data)
        handle(conn)

      {:tcp_closed, ^socket} ->
        Log.trace("#{cid} closed")

      unexpected ->
        Log.warn("#{cid} unexpected #{Api.inspect?(unexpected)}")
        # this kills and restarts the server as well
        exit(:kill)
    end
  end
end
