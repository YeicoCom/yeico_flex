defmodule Flex.ModbusDevices.PUtils do
  use Flex.Use

  @new %{type: "RDI", slave: 1, address: 0, encoding: "NONE", names: ""}
  @types ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"]
  @encodings ["NONE", "U16BE", "U16LE", "S16BE", "S16LE", "F32BE", "F32LE"]
  @options %{types: @types, encodings: @encodings}

  def new, do: @new
  def options, do: @options

  def limits(point) do
    %{type: type} = dirtype(point)
    Points.get_limits(type)
  end

  def apply(arg) do
    case arg do
      {points, action, pi} ->
        case action do
          "add" -> points ++ [@new]
          "del" -> List.delete_at(points, pi)
          "up" -> switch(points, pi - 1)
          "down" -> switch(points, pi)
        end

      {item, action} ->
        case action do
          "enable" -> Map.put(item, :status, :enabled)
          "disable" -> Map.put(item, :status, :disabled)
        end
    end
  end

  def accessors(point = %{names: names, encoding: encoding}) do
    %{dir: dir, type: type} = dirtype(point)
    %{parse: parse} = Modbus.get_encoder(encoding)

    for name <- split(names) do
      tag = Points.get_tag(type, name)
      key = Points.get_key(dir, type, name)
      get = fn -> Points.get_value(key) end
      put = fn value -> Points.put_value(key, value) end

      %{
        tag: tag,
        dir: dir,
        key: key,
        get: get,
        put: put,
        type: type,
        name: name,
        parse: parse
      }
    end
  end

  def parse(item = %{points: points}, params) do
    type = params["type"]
    encoding = params["encoding"]
    slave = params["slave"] |> Enum.map(&toint?/1)
    address = params["address"] |> Enum.map(&toint?/1)

    names =
      params["names"]
      |> Enum.map(fn names ->
        String.split(names, ",") |> Enum.map(&String.trim/1) |> Enum.join(",")
      end)

    {points, _, _, _, _, _} =
      for _ <- points, reduce: {[], slave, address, type, encoding, names} do
        {points, [s | slave], [a | address], [t | type], [e | encoding], [n | names]} ->
          {[%{slave: s, address: a, type: t, encoding: e, names: n} | points], slave, address,
           type, encoding, names}
      end

    points = points |> Enum.reverse()
    Map.put(item, :points, points)
  end

  defp switch(points, pi) do
    {prefix, [a, b | tail]} = Enum.split(points, pi)
    prefix ++ [b, a | tail]
  end

  defp split(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  defp toint?(str) do
    case Integer.parse(str) do
      {v, ""} -> v
      _ -> nil
    end
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
