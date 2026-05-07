defmodule Modbus.Command do
  alias Modbus.Encoder
  alias Modbus.Parser
  use Flex

  defp check_max(v, max) when is_integer(v) do
    if v <= 0 or v > max, do: throw("Invalid data range")
    v
  end

  defp check_max(v, max) when is_list(v) do
    n = length(v)
    if n <= 0 or n > max, do: throw("Invalid data range")
    v
  end

  defp parse(line) do
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
      case Parser.parse_n(s) do
        {v, ""} when v >= 0 and v <= 255 -> v
        {_, ""} -> throw("Invalid slave range")
        _ -> throw("Invalid slave format")
      end

    a = params["a"]
    if !a, do: throw("Missing address param")

    a =
      case Parser.parse_n(a) do
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

    enc = Encoder.for(e)

    {d, get} =
      case {c, e} do
        {:rir, _} ->
          d = Parser.parse_dc(d) |> check_max(div(254, 2 * enc.factor))
          {enc.factor * d, enc.decode}

        {:rhr, _} ->
          d = Parser.parse_dc(d) |> check_max(div(254, 2 * enc.factor))
          {enc.factor * d, enc.decode}

        {:phr, _} ->
          d = enc.parse.(d)
          {enc.encode.(d), & &1}

        {_, "NONE"} ->
          d =
            case c do
              :ri -> Parser.parse_dc(d) |> check_max(8 * 255)
              :rc -> Parser.parse_dc(d) |> check_max(8 * 255)
              :fc -> Parser.parse_dd(d) |> check_max(8 * 255)
            end

          {d, & &1}
      end

    %{cmd: {c, s, a, d}, get: get}
  end

  def safe_parse(line) do
    case Api.safe(&parse/1, line) do
      {:ok, res} ->
        {:ok, res}

      {:error, result = %{error: error}} ->
        Log.warn(error: result)
        {:error, error}

      {:error, error} ->
        Log.warn(error: error)
        {:error, error}
    end
  end
end

:ok
