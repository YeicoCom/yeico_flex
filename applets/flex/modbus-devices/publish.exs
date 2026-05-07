defmodule Flex.ModbusDevices.Publish do
  alias Flex.ModbusDevices.PUtils
  use Flex

  def setup _ do
    Api.subget!("flex:modbus-devices:items")
    |> Enum.each(fn {_id, device} ->
      Mdb.register!("flex:points:source", "status:#{device.name}")

      for point <- device.points do
        for %{dir: dir, tag: tag} <- PUtils.accessors(point) do
          Mdb.register!("flex:points:#{dir}", tag)
        end
      end
    end)

    receive do: (_ -> nil)
    :reload
  end
end

:ok
