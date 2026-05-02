use Terminal

proto = mb.api.(:proto, get: proto)
slave = mb.api.(:slave, proto: proto, key: "flex:modbus-slave:model")

handle = fn {loop, conn = %{socket: socket}} ->
  receive do
    {:tcp, ^socket, data} ->
      :ok = Tcp.write(conn, slave.(data))
      loop.({loop, conn})

    unexpected ->
      Api.debug(unexpected: unexpected)
  end
end

accept = fn loop, socket ->
  {:ok, conn} = Tcp.accept(socket)
  Api.info("Modbus slave client: #{conn.peer.ip}:#{conn.peer.port}")
  task = Api.async(handle, {handle, conn})
  Tcp.owner(conn, task)
  loop.(loop, socket)
end

listen = fn ->
  {:ok, socket} = Tcp.listen("127.0.0.1", port, active: true)
  Api.info("Modbus slave #{proto.(:id)} port: #{socket.port}")
  accept.(accept, socket)
end

Api.loop(dms, listen)

:ok
