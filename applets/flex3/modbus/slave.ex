defmodule Modbus.Slave do
  alias Modbus.Protocol
  use Applet.Alias

  defp get(key, slave, type, address, count) do
    model = Adb.get(key, %{})

    for i <- 0..(count - 1) do
      Map.get(model, "#{slave}:#{type}:#{address + i}", 0)
    end
  end

  defp put(key, slave, type, address, values) do
    patch =
      for {v, i} <- Enum.with_index(values), reduce: %{} do
        patch -> Map.put(patch, "#{slave}:#{type}:#{address + i}", v)
      end

    Adb.update(key, patch, &Map.merge(&1, patch))

    nil
  end

  def apply(proto, key, data) do
    {cmd, tid} = Protocol.parse_req(proto, data)
    # Log.trace(cmd: cmd, tid: tid)

    values =
      case cmd do
        {:ri, slave, address, count} ->
          get(key, slave, "d", address, count)

        {:rc, slave, address, count} ->
          get(key, slave, "d", address, count)

        {:rir, slave, address, count} ->
          get(key, slave, "r", address, count)

        {:rhr, slave, address, count} ->
          get(key, slave, "r", address, count)

        {:fc, slave, address, values} when is_list(values) ->
          put(key, slave, "d", address, values)

        {:fc, slave, address, value} ->
          put(key, slave, "d", address, [value])

        {:phr, slave, address, values} when is_list(values) ->
          put(key, slave, "r", address, values)

        {:phr, slave, address, value} ->
          put(key, slave, "r", address, [value])
      end

    Protocol.pack_res(proto, cmd, values, tid)
  end
end
