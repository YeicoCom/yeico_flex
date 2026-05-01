use Terminal

proto = libModbus.proto.(proto)

get = fn slave, code, address, count ->
  model = Adb.get("flex:modbus-slave:model")

  for i <- 0..(count - 1) do
    Map.get(model, "#{slave}:#{code}:#{address + i}", 0)
  end
end

put = fn slave, code, address, values ->
  patch =
    for {v, i} <- Enum.with_index(values), reduce: %{} do
      patch -> Map.put(patch, "#{slave}:#{code}:#{address + i}", v)
    end

  Adb.update("flex:modbus-slave:model", patch, &Map.merge(&1, patch))
  Bus.broadcast!("flex:modbus-slave:model", patch)

  nil
end

handle = fn {loop, conn = %{socket: socket}} ->
  receive do
    {:tcp, ^socket, data} ->
      {cmd, tid} = proto.({:parse_req, data})
      Api.debug(cmd: cmd, tid: tid)

      values =
        case cmd do
          {:ri, slave, address, count} -> get.(slave, "d", address, count)
          {:rc, slave, address, count} -> get.(slave, "d", address, count)
          {:rir, slave, address, count} -> get.(slave, "r", address, count)
          {:rhr, slave, address, count} -> get.(slave, "r", address, count)
          {:fc, slave, address, values} -> put.(slave, "d", address, values)
          {:phr, slave, address, values} -> put.(slave, "r", address, values)
        end

      resp = proto.({:pack_res, cmd, values, tid})
      :ok = Tcp.write(conn, resp)
      loop.({loop, conn})

    unexpected ->
      Api.warn(unexpected: unexpected)
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
