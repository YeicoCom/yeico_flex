use Terminal

new = %{type: "RDI", slave: 1, address: 0, encoding: "none", names: ""}

types = ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"]
encodings = ["NONE", "U16BE", "U16LE", "S16BE", "S16LE", "F32BE", "F32LE"]

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

# use official erlang type names
dirtype = fn
  %{type: "RDI"} -> %{dir: :source, type: :bit}
  %{type: "RDO"} -> %{dir: :source, type: :bit}
  %{type: "WDO"} -> %{dir: :sink, type: :bit}
  %{type: "RRI", encoding: "F32BE"} -> %{dir: :source, type: :float}
  %{type: "RRO", encoding: "F32BE"} -> %{dir: :source, type: :float}
  %{type: "WRO", encoding: "F32BE"} -> %{dir: :sink, type: :float}
  %{type: "RRI", encoding: "F32LE"} -> %{dir: :source, type: :float}
  %{type: "RRO", encoding: "F32LE"} -> %{dir: :source, type: :float}
  %{type: "WRO", encoding: "F32LE"} -> %{dir: :sink, type: :float}
  %{type: "RRI", encoding: "U16BE"} -> %{dir: :source, type: :uint16}
  %{type: "RRO", encoding: "U16BE"} -> %{dir: :source, type: :uint16}
  %{type: "WRO", encoding: "U16BE"} -> %{dir: :sink, type: :uint16}
  %{type: "RRI", encoding: "U16LE"} -> %{dir: :source, type: :uint16}
  %{type: "RRO", encoding: "U16LE"} -> %{dir: :source, type: :uint16}
  %{type: "WRO", encoding: "U16LE"} -> %{dir: :sink, type: :uint16}
  %{type: "RRI"} -> %{dir: :source, type: :uint16}
  %{type: "RRO"} -> %{dir: :source, type: :uint16}
  %{type: "WRO"} -> %{dir: :sink, type: :uint16}
end

switch = fn points, pi ->
  {prefix, [a, b | tail]} = Enum.split(points, pi)
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

split = fn str ->
  str
  |> String.split(",")
  |> Enum.map(&String.trim/1)
end

accessors = fn point = %{names: names, encoding: encoding} ->
  %{get_value: get_value, put_value: put_value} = pt
  %{dir: dir, type: type} = dirtype.(point)
  %{parse: parse} = mb.api.(:encoder, get: encoding)

  for name <- split.(names) do
    key = pt.get_key.(dir, type, name)
    get = fn -> get_value.(key) end
    put = fn value -> put_value.(key, value) end
    %{name: name, key: key, get: get, put: put, parse: parse}
  end
end

:ok
