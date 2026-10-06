defmodule Modbus.Parser do
  def parse_n(value) do
    case String.first(value) do
      "d" -> Integer.parse(String.slice(value, 1..-1//1), 10)
      "h" -> Integer.parse(String.slice(value, 1..-1//1), 16)
      "b" -> Integer.parse(String.slice(value, 1..-1//1), 2)
      _ -> Integer.parse(value, 10)
    end
  end

  def parse_dc(value) do
    case parse_n(value) do
      {v, ""} -> v
      _ -> throw("Invalid data param")
    end
  end

  def parse_dd(value) do
    with true <- Regex.match?(~r/^[01]+$/, value) do
      value |> String.graphemes() |> Enum.map(&String.to_integer/1)
    else
      _ -> throw("Invalid data param")
    end
  end

  def parse_du16(value) do
    String.split(value, ":")
    |> Enum.map(fn part ->
      case parse_n(part) do
        {v, ""} when v >= 0 and v <= 65_535 -> v
        {_, ""} -> throw("Invalid data range")
        _ -> throw("Invalid data format")
      end
    end)
  end

  def parse_ds16(value) do
    String.split(value, ":")
    |> Enum.map(fn part ->
      case parse_n(part) do
        {v, ""} when v >= -32_768 and v <= 32_767 -> v
        {_, ""} -> throw("Invalid data range")
        _ -> throw("Invalid data format")
      end
    end)
  end

  def parse_df32(value) do
    String.split(value, ":")
    |> Enum.map(fn part ->
      case Float.parse(part) do
        {v, ""} -> v
        _ -> throw("Invalid data format")
      end
    end)
  end
end
