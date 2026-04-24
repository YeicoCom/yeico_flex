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

check_max = fn
  v, max when is_integer(v) ->
    if v <= 0 or v > max, do: throw("Invalid data range")
    v

  v, max when is_list(v) ->
    n = length(v)
    if n <= 0 or n > max, do: throw("Invalid data range")
    v
end

# https://erlang.org/euc/00/bit_syntax.html (6.4 Defaults)
# Erlang defaults to big-endian, unsigned, integer.
reg16_switch = fn value ->
  <<b0::8, b1::8>> = <<value::size(16)>>
  <<value::size(16)>> = <<b1::8, b0::8>>
  value
end

# apparently <<d::float-32>> auto converts d to float (from integer and double)
# both d=1 and d=1.0 render same <<d::float-32>>
encoder = fn
  "NONE" ->
    %{
      rf: 1,
      set: & &1,
      get: & &1,
      parse: parse_du16
    }

  # opto22
  "F32BE" ->
    %{
      rf: 2,
      set: fn d -> modbus.float.({:to_be, d}) end,
      get: fn d -> modbus.float.({:from_be, d}) end,
      parse: parse_df32
    }

  "F32LE" ->
    %{
      rf: 2,
      set: fn d -> modbus.float.({:to_le, d}) end,
      get: fn d -> modbus.float.({:from_le, d}) end,
      parse: parse_df32
    }

  "U16BE" ->
    %{
      rf: 1,
      set: & &1,
      get: & &1,
      parse: parse_du16
    }

  # turck vibration and temp sensor CMVT-QR20-IOLX3-H1141
  "U16LE" ->
    %{
      rf: 1,
      set: &for(v <- &1, do: reg16_switch.(v)),
      get: &for(v <- &1, do: reg16_switch.(v)),
      parse: parse_du16
    }
end

parse_p = fn line ->
  line = line |> String.split("#") |> List.first()
  line = String.downcase(line)

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
      {_, ""} -> throw("Invalid slave range")
      _ -> throw("Invalid slave format")
    end

  a = params["a"]
  if !a, do: throw("Missing address param")

  a =
    case parse_n.(a) do
      {v, ""} when v >= 0 and v <= 65535 -> v
      {_, ""} -> throw("Invalid address range")
      _ -> throw("Invalid address format")
    end

  c = params["c"]
  if !c, do: throw("Missing code param")

  c =
    case c do
      "rdi" -> "ri"
      "rdo" -> "rc"
      "wdo" -> "fc"
      "rri" -> "rir"
      "rro" -> "rhr"
      "wro" -> "phr"
      _ -> c
    end

  c =
    case c in ["ri", "rc", "fc", "rir", "rhr", "phr"] do
      true -> String.to_atom(c)
      _ -> throw("Invalid code param")
    end

  d = params["d"]
  if !d, do: throw("Missing data param")

  e = params["e"]

  if c in [:ri, :fc, :rc] do
    if e, do: throw("Unsupported encoding param")
  end

  e = e || "none"
  e = String.upcase(e)

  %{rf: rf, set: set, get: get, parse: parse_dr} = encoder.(e)

  {d, get} =
    case {c, e} do
      {:rir, _} ->
        d = parse_dc.(d) |> check_max.(div(254, 2 * rf))
        {rf * d, get}

      {:rhr, _} ->
        d = parse_dc.(d) |> check_max.(div(254, 2 * rf))
        {rf * d, get}

      {:phr, _} ->
        d = parse_dr.(d)
        {set.(d), & &1}

      {_, "NONE"} ->
        d =
          case c do
            :ri -> parse_dc.(d) |> check_max.(8 * 255)
            :rc -> parse_dc.(d) |> check_max.(8 * 255)
            :fc -> parse_dd.(d) |> check_max.(8 * 255)
          end

        {d, & &1}
    end

  %{cmd: {c, s, a, d}, get: get}
end

parse = fn line ->
  case Api.safe(parse_p, line) do
    {:ok, res} ->
      {:ok, res}

    {:error, result = %{error: error}} ->
      Api.warn(error: result)
      {:error, error}

    {:error, error} ->
      Api.warn(error: error)
      {:error, error}
  end
end

%{
  encoder: encoder,
  parse: parse
}
