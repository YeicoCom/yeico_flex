use Terminal

loop = fn ->
  Api.subget!("flex:modbus-devices:items")
  |> Enum.each(fn {_id, device} ->
    # src = "modbus:#{device.proto},#{device.ip}:#{device.port},#{device.name}"

    for point <- device.points do
      for %{dir: dir, key: key} <- plib.accessors.(point) do
        tag = String.trim_leading(key, "#{dir}:")
        Mdb.register!("flex:points:#{dir}", tag)
      end
    end
  end)

  receive do: (_ -> nil)
end

Api.loop(0, loop)

:ok
