defmodule Flex.ModbusSlave do
  use Flex.Service
  use Terminal

  defp specs(),
    do: %{
      key: %{initial: nil, check: :binary},
      port: %{initial: 0, check: {:integer, 0, 65_535}},
      proto: %{initial: "TCP", check: {:in, ["TCP", "RTU"]}},
      ip: %{initial: "127.0.0.1", check: {:in, ["127.0.0.1", "0.0.0.0"]}}
    }

  defp setup(%{port: port, ip: ip, proto: proto, key: key}) do
    sid = Process.get(:__sid__)
    protom = Modbus.Protocol.by_name(proto)
    apply = fn data -> Modbus.Slave.apply(protom, key, data) end
    {:ok, socket} = Tcp.listen(ip, port, active: true)
    clean(fn -> Tcp.close(socket) end)
    Log.debug("#{sid} started")
    accept(socket, apply)
  end

  defp accept(socket, apply) do
    Api.flush(toms: 0)
    {:ok, conn = %{peer: peer}} = Tcp.accept(socket)
    sid = Process.get(:__sid__)
    cid = "#{sid}:#{peer.ip}:#{peer.port}"
    Log.trace("#{cid} accepted")
    conn = Map.put(conn, :cid, cid)
    conn = Map.put(conn, :apply, apply)
    task = Api.async(&handle/1, conn, tag: cid)
    Tcp.owner(conn, task)
    accept(socket, apply)
  end

  defp handle(conn = %{socket: socket, cid: cid, apply: apply}) do
    receive do
      {:tcp, ^socket, data} ->
        :ok = Tcp.write(conn, apply.(data))
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
