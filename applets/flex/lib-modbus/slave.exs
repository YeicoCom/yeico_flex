defmodule Modbus.Slave do
  alias Modbus.Protocol
  use Flex

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
    # Log.debug(cmd: cmd, tid: tid)

    values =
      case cmd do
        {:ri, slave, address, count} -> get(key, slave, "d", address, count)
        {:rc, slave, address, count} -> get(key, slave, "d", address, count)
        {:rir, slave, address, count} -> get(key, slave, "r", address, count)
        {:rhr, slave, address, count} -> get(key, slave, "r", address, count)
        {:fc, slave, address, values} -> put(key, slave, "d", address, values)
        {:phr, slave, address, values} -> put(key, slave, "r", address, values)
      end

    Protocol.pack_res(proto, cmd, values, tid)
  end
end

:ok
