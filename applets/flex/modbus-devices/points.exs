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

enctype = fn
  "NONE" -> :uint16
  "U16BE" -> :uint16
  "S16BE" -> :sint16
  "F32BE" -> :float
  "U16LE" -> :uint16
  "S16LE" -> :sint16
  "F32LE" -> :float
end

dirtype = fn
  %{type: "RDI"} -> %{dir: :source, type: :bit}
  %{type: "RDO"} -> %{dir: :source, type: :bit}
  %{type: "WDO"} -> %{dir: :sink, type: :bit}
  %{type: "RRI", encoding: enc} -> %{dir: :source, type: enctype.(enc)}
  %{type: "RRO", encoding: enc} -> %{dir: :source, type: enctype.(enc)}
  %{type: "WRO", encoding: enc} -> %{dir: :sink, type: enctype.(enc)}
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

parse = fn device = %{points: points}, params ->
  type = params["type"]
  encoding = params["encoding"]
  slave = params["slave"] |> Enum.map(toint?)
  address = params["address"] |> Enum.map(toint?)

  names =
    params["names"]
    |> Enum.map(fn names ->
      String.split(names, ",") |> Enum.map(&String.trim/1) |> Enum.join(",")
    end)

  {points, _, _, _, _, _} =
    for _ <- points, reduce: {[], slave, address, type, encoding, names} do
      {points, [s | slave], [a | address], [t | type], [e | encoding], [n | names]} ->
        {[%{slave: s, address: a, type: t, encoding: e, names: n} | points], slave, address, type,
         encoding, names}
    end

  points = points |> Enum.reverse()
  Map.put(device, :points, points)
end

:ok
