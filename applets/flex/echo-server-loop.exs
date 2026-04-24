use Terminal

handle = fn {loop, conn = %{socket: socket}} ->
  receive do
    {:tcp, ^socket, data} ->
      :ok = Tcp.write(conn, data)
      loop.({loop, conn})

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

accept = fn loop, socket ->
  {:ok, conn} = Tcp.accept(socket)
  Api.info("Echo server client: #{conn.peer.ip}:#{conn.peer.port}")
  task = Api.async(handle, {handle, conn})
  Tcp.owner(conn, task)
  loop.(loop, socket)
end

listen = fn ->
  {:ok, socket} = Tcp.listen(ip, port, active: true)
  Api.info("Echo server port: #{socket.port}")
  accept.(accept, socket)
end

Api.loop(dms, listen)

:ok
