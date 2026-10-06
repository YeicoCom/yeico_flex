defmodule Modbus.Points do
  alias Flex3.Points

  def accessors(point = %{names: names}) do
    %{dir: dir, type: type} = dirtype(point)

    for name <- split(names) do
      key = Points.get_key(dir, type, name)
      get = fn -> Points.get_value(key) end
      put = fn value -> Points.put_value(key, value) end

      %{
        get: get,
        put: put
      }
    end
  end

  defp split(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp enctype("NONE"), do: :uint16
  defp enctype("U16BE"), do: :uint16
  defp enctype("S16BE"), do: :sint16
  defp enctype("F32BE"), do: :float
  defp enctype("U16LE"), do: :uint16
  defp enctype("S16LE"), do: :sint16
  defp enctype("F32LE"), do: :float

  defp dirtype(%{type: "RDI"}), do: %{dir: :source, type: :bit}
  defp dirtype(%{type: "RDO"}), do: %{dir: :source, type: :bit}
  defp dirtype(%{type: "WDO"}), do: %{dir: :sink, type: :bit}
  defp dirtype(%{type: "RRI", encoding: enc}), do: %{dir: :source, type: enctype(enc)}
  defp dirtype(%{type: "RRO", encoding: enc}), do: %{dir: :source, type: enctype(enc)}
  defp dirtype(%{type: "WRO", encoding: enc}), do: %{dir: :sink, type: enctype(enc)}
end
