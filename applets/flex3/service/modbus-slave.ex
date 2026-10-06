defmodule Flex3.ModbusSlave do
  use Flex3.Service
  use Terminal

  defp initial() do
    %{
      key: nil,
      proto: "TCP",
      ip: "127.0.0.1",
      port: 0
    }
  end

  defp checks() do
    %{
      key: :binary,
      proto: {:in, ["TCP", "RTU"]},
      port: {:integer, 0, 65_535},
      ip: {:in, ["127.0.0.1", "0.0.0.0"]}
    }
  end

  defp name(%{port: port, ip: ip, proto: proto}) do
    "modbus-slave:#{port}:#{ip}:#{proto}"
  end

  defp setup(%{port: port, ip: ip, proto: proto, key: key}) do
    protom = Flex3.Modbus.get_proto(proto)
    apply = fn data -> Flex3.Modbus.slave_apply(protom, key, data) end
    {:ok, socket = %{port: port}} = Tcp.listen(ip, port, active: true)
    clean(fn -> Tcp.close(socket) end)
    sid = "modbus-slave:#{port}:#{ip}:#{proto}"
    Log.debug("#{sid} started")
    accept(socket, apply)
  end

  defp accept(socket = %{port: port}, apply) do
    Api.flush(toms: 0)
    {:ok, conn = %{peer: peer}} = Tcp.accept(socket)
    cid = "modbus-slave:#{port}:#{peer.ip}:#{peer.port}"
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
