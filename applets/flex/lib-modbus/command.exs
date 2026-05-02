use Terminal

check_max = fn
  v, max when is_integer(v) ->
    if v <= 0 or v > max, do: throw("Invalid data range")
    v

  v, max when is_list(v) ->
    n = length(v)
    if n <= 0 or n > max, do: throw("Invalid data range")
    v
end

this = fn line ->
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
    case parser.parse_n.(s) do
      {v, ""} when v >= 0 and v <= 255 -> v
      {_, ""} -> throw("Invalid slave range")
      _ -> throw("Invalid slave format")
    end

  a = params["a"]
  if !a, do: throw("Missing address param")

  a =
    case parser.parse_n.(a) do
      {v, ""} when v >= 0 and v <= 65535 -> v
      {_, ""} -> throw("Invalid address range")
      _ -> throw("Invalid address format")
    end

  c = params["c"]
  if !c, do: throw("Missing code param")

  c =
    case c do
      "rdi" -> :ri
      "rdo" -> :rc
      "wdo" -> :fc
      "rri" -> :rir
      "rro" -> :rhr
      "wro" -> :phr
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

  %{rf: rf, set: set, get: get, parse: parse_dr} = encoder.get.(e)

  {d, get} =
    case {c, e} do
      {:rir, _} ->
        d = parser.parse_dc.(d) |> check_max.(div(254, 2 * rf))
        {rf * d, get}

      {:rhr, _} ->
        d = parser.parse_dc.(d) |> check_max.(div(254, 2 * rf))
        {rf * d, get}

      {:phr, _} ->
        d = parse_dr.(d)
        {set.(d), & &1}

      {_, "NONE"} ->
        d =
          case c do
            :ri -> parser.parse_dc.(d) |> check_max.(8 * 255)
            :rc -> parser.parse_dc.(d) |> check_max.(8 * 255)
            :fc -> parser.parse_dd.(d) |> check_max.(8 * 255)
          end

        {d, & &1}
    end

  %{cmd: {c, s, a, d}, get: get}
end

parse = fn line ->
  case Api.safe(this, line) do
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

:ok
