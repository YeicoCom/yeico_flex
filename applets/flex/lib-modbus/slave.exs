use Terminal

build = fn proto, key ->
  get = fn slave, type, address, count ->
    model = Adb.get(key, %{})

    for i <- 0..(count - 1) do
      Map.get(model, "#{slave}:#{type}:#{address + i}", 0)
    end
  end

  put = fn slave, type, address, values ->
    patch =
      for {v, i} <- Enum.with_index(values), reduce: %{} do
        patch -> Map.put(patch, "#{slave}:#{type}:#{address + i}", v)
      end

    Adb.update(key, patch, &Map.merge(&1, patch))

    nil
  end

  fn data ->
    {cmd, tid} = proto.({:parse_req, data})
    # Api.debug(cmd: cmd, tid: tid)

    values =
      case cmd do
        {:ri, slave, address, count} -> get.(slave, "d", address, count)
        {:rc, slave, address, count} -> get.(slave, "d", address, count)
        {:rir, slave, address, count} -> get.(slave, "r", address, count)
        {:rhr, slave, address, count} -> get.(slave, "r", address, count)
        {:fc, slave, address, values} -> put.(slave, "d", address, values)
        {:phr, slave, address, values} -> put.(slave, "r", address, values)
      end

    proto.({:pack_res, cmd, values, tid})
  end
end

:ok
