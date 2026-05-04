use Terminal

loop = fn ->
  Api.subget!("flex:modbus-devices:items")
  |> Enum.each(fn {_id, device} ->
    # src = "modbus:#{device.proto},#{device.ip}:#{device.port},#{device.name}"

    for point <- device.points do
      for %{dir: dir, tag: tag} <- plib.accessors.(point) do
        Mdb.register!("flex:points:#{dir}", tag)
      end
    end
  end)

  receive do: (_ -> nil)
end

Api.loop(0, loop)

:ok
