use Terminal

new = %{type: "RDI", slave: 1, address: 0, encoding: "none", names: ""}

types = ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"]
encodings = ["NONE", "F32BE", "F32LE", "U16BE", "U16LE"]

options = %{
  types: types,
  encodings: encodings
}

toint? = fn str ->
  case Integer.parse(str) do
    {v, ""} -> v
    _ -> nil
  end
end

# default value here must cover all types below
get = fn key ->
  Adb.get("flex:point:#{key}", 0)
end

put = fn key, val ->
  Api.putcast!("flex:point:#{key}", val)
end

# use official erlang type names
type = fn
  %{type: "RDI"} -> {:source, :bit}
  %{type: "RDO"} -> {:source, :bit}
  %{type: "WDO"} -> {:sink, :bit}
  %{type: "RRI", encoding: "F32BE"} -> {:source, :float}
  %{type: "RRO", encoding: "F32BE"} -> {:source, :float}
  %{type: "WRO", encoding: "F32BE"} -> {:sink, :float}
  %{type: "RRI", encoding: "F32LE"} -> {:source, :float}
  %{type: "RRO", encoding: "F32LE"} -> {:source, :float}
  %{type: "WRO", encoding: "F32LE"} -> {:sink, :float}
  %{type: "RRI", encoding: "U16BE"} -> {:source, :uint16}
  %{type: "RRO", encoding: "U16BE"} -> {:source, :uint16}
  %{type: "WRO", encoding: "U16BE"} -> {:sink, :uint16}
  %{type: "RRI", encoding: "U16LE"} -> {:source, :uint16}
  %{type: "RRO", encoding: "U16LE"} -> {:source, :uint16}
  %{type: "WRO", encoding: "U16LE"} -> {:sink, :uint16}
  %{type: "RRI"} -> {:source, :uint16}
  %{type: "RRO"} -> {:source, :uint16}
  %{type: "WRO"} -> {:sink, :uint16}
end

# ensure that a relocated point wont get an unexpected value
key = fn
  {dir, type}, name ->
    "#{dir}:#{type}:#{name}"

  point, name ->
    {dir, type} = type.(point)
    "#{dir}:#{type}:#{name}"
end

names = fn str ->
  str
  |> String.split(",")
  |> Enum.map(&String.trim/1)
end

switch = fn points, pi ->
  {prefix, [a, b | tail]} = Enum.split(points, pi) |> Api.debug()
  prefix ++ [b, a | tail]
end

apply = fn
  {points, action, pi} ->
    case action do
      "add" -> points ++ [new]
      "del" -> List.delete_at(points, pi)
      "up" -> switch.(points, pi - 1)
      "down" -> switch.(points, pi)
    end

  {device, action} ->
    case action do
      "enable" -> Map.put(device, :status, :enabled)
      "disable" -> Map.put(device, :status, :disabled)
    end
end

:ok
