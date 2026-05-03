use Terminal

loop = fn ->
  Api.subget!("flex:modbus-devices:items")
  |> Enum.each(fn {_id, device} ->
    src = "modbus:#{device.proto},#{device.ip}:#{device.port},#{device.name}"

    for point <- device.points do
      for {name, ni} <- Enum.with_index(plib.names.(point.names)) do
        addr = "#{point.type}:#{point.encoding}:#{point.address + ni}"
        {dir, type} = plib.type.(point)
        key = plib.key.({dir, type}, name)

        entry = %{
          src: src,
          key: key,
          addr: addr,
          dir: dir,
          type: type,
          name: name
        }

        Mdb.register!("flex:points", entry)
        Mdb.register!("flex:points:#{dir}", entry)
      end
    end
  end)

  receive do: (_ -> nil)
end

Api.loop(0, loop)

:ok
