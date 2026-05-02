use Terminal

parse_n = fn value ->
  case String.first(value) do
    "d" -> Integer.parse(String.slice(value, 1..-1//1), 10)
    "h" -> Integer.parse(String.slice(value, 1..-1//1), 16)
    "b" -> Integer.parse(String.slice(value, 1..-1//1), 2)
    _ -> Integer.parse(value, 10)
  end
end

parse_dd = fn value ->
  with true <- Regex.match?(~r/^[01]+$/, value) do
    value |> String.graphemes() |> Enum.map(&String.to_integer/1)
  else
    _ -> throw("Invalid data param")
  end
end

parse_df32 = fn value ->
  String.split(value, ":")
  |> Enum.map(fn part ->
    case Float.parse(part) do
      {v, ""} -> v
      _ -> throw("Invalid data format")
    end
  end)
end

parse_du16 = fn value ->
  String.split(value, ":")
  |> Enum.map(fn part ->
    case parse_n.(part) do
      {v, ""} when v >= 0 and v <= 65535 -> v
      {_, ""} -> throw("Invalid data range")
      _ -> throw("Invalid data format")
    end
  end)
end

parse_dc = fn value ->
  case parse_n.(value) do
    {v, ""} -> v
    _ -> throw("Invalid data param")
  end
end

:ok
