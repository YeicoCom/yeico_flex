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
      _ -> throw("Invalid data param format")
    end
  end)
end

parse_dr = fn value ->
  String.split(value, ":")
  |> Enum.map(fn part ->
    case parse_n.(part) do
      {v, ""} when v >= 0 and v <= 65535 -> v
      {_, ""} -> throw("Invalid data param range")
      _ -> throw("Invalid data param format")
    end
  end)
end

parse_dc = fn value ->
  case parse_n.(value) do
    {v, ""} -> v
    _ -> throw("Invalid data param")
  end
end

check_max = fn
  v, max when is_integer(v) ->
    if v <= 0 or v > max, do: throw("Invalid data range")
    v

  v, max when is_list(v) ->
    n = length(v)
    if n <= 0 or n > max, do: throw("Invalid data range")
    v
end

parse_p = fn line ->
  line = line |> String.split("#") |> List.first()

  params =
    String.split(line, ",", trim: true)
    |> Enum.map(&String.split(&1, "=", parts: 2))
    |> Enum.map(fn
      [k, v] -> {String.trim(k), String.trim(v)}
      [k] -> {String.trim(k), nil}
    end)
    |> Enum.into(%{})

  s = params["s"]
  if !s, do: throw("Missing slave param")

  s =
    case parse_n.(s) do
      {v, ""} when v >= 0 and v <= 255 -> v
      {_, ""} -> throw("Invalid slave param range")
      _ -> throw("Invalid slave param format")
    end

  a = params["a"]
  if !a, do: throw("Missing address param")

  a =
    case parse_n.(a) do
      {v, ""} when v >= 0 and v <= 65535 -> v
      {_, ""} -> throw("Invalid address param range")
      _ -> throw("Invalid address param format")
    end

  c = params["c"]
  if !c, do: throw("Missing code param")

  c =
    case c do
      "rdi" -> "ri"
      "rdo" -> "rc"
      "wdo" -> "fc"
      "rwi" -> "rir"
      "rwo" -> "rhr"
      "wwo" -> "phr"
      _ -> c
    end

  c =
    case c in ["ri", "fc", "rc", "rir", "phr", "rhr"] do
      true -> String.to_atom(c)
      _ -> throw("Invalid code param")
    end

  d = params["d"]
  if !d, do: throw("Missing data param")

  f = params["f"]

  if c in [:ri, :fc, :rc] do
    if f, do: throw("Unsupported format param")
  end

  {d, get} =
    case {c, f} do
      {:rir, "f32be"} ->
        d = parse_dc.(d) |> check_max.(div(254, 4))
        {2 * d, fn d -> modbus.float.({:from_be, d}) end}

      {:phr, "f32be"} ->
        d = parse_df32.(d)
        {modbus.float.({:to_be, d}), & &1}

      {:rhr, "f32be"} ->
        d = parse_dc.(d) |> check_max.(div(254, 4))
        {2 * d, fn d -> modbus.float.({:from_be, d}) end}

      {:rir, "f32le"} ->
        d = parse_dc.(d) |> check_max.(div(254, 4))
        {2 * d, fn d -> modbus.float.({:from_le, d}) end}

      {:phr, "f32le"} ->
        d = parse_df32.(d)
        {modbus.float.({:to_le, d}), & &1}

      {:rhr, "f32le"} ->
        d = parse_dc.(d) |> check_max.(div(254, 4))
        {2 * d, fn d -> modbus.float.({:from_le, d}) end}

      {_, nil} ->
        d =
          case c do
            :ri -> parse_dc.(d) |> check_max.(8 * 255)
            :fc -> parse_dd.(d) |> check_max.(8 * 255)
            :rc -> parse_dc.(d) |> check_max.(8 * 255)
            :rir -> parse_dc.(d) |> check_max.(div(254, 2))
            :phr -> parse_dr.(d) |> check_max.(div(254, 2))
            :rhr -> parse_dc.(d) |> check_max.(div(254, 2))
          end

        {d, & &1}
    end

  {{c, s, a, d}, get}
end

parse = fn line ->
  case Api.safe(parse_p, line) do
    {:ok, {cmd, ff}} -> {:ok, cmd, ff}
    {:error, %{error: error}} -> {:error, error}
    {:error, error} -> {:error, error}
  end
end

%{
  parse: parse
}
