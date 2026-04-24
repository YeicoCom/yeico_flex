use Terminal

publish_modbus_devices = fn ->
  Api.subget!("flex:modbus-devices:items")
  |> Enum.each(fn {_id, device} ->
    src = "modbus:#{device.proto},#{device.ip}:#{device.port},#{device.name}"

    for point <- device.points do
      for {name, ni} <- Enum.with_index(plib.names.(point.names)) do
        addr = "#{point.type}:#{point.encoding}:#{point.address + ni}"
        {dir, type} = plib.type.(point.type, point.encoding)
        Mdb.register!("flex:points", %{src: src, addr: addr, dir: dir, type: type, name: name})
      end
    end
  end)

  receive do: (_ -> nil)
end

Api.loop(0, publish_modbus_devices)
