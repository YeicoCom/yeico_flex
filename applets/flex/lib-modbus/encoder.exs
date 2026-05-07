defmodule Modbus.Encoder do
  alias Modbus.Convert
  alias Modbus.Parser

  def for("NONE") do
    %{
      factor: 1,
      decode: & &1,
      encode: & &1,
      parse: &Parser.parse_du16/1
    }
  end

  def for("U16BE") do
    %{
      factor: 1,
      decode: &for(v <- &1, do: Convert.to(:u16be, v)),
      encode: &for(v <- &1, do: Convert.from(:u16be, v)),
      parse: &Parser.parse_du16/1
    }
  end

  # turck vibration and temp sensor CMVT-QR20-IOLX3-H1141
  # FIXME: confirm if such sensor encoding is actually signed
  def for("U16LE") do
    %{
      factor: 1,
      decode: &for(v <- &1, do: Convert.to(:u16le, v)),
      encode: &for(v <- &1, do: Convert.from(:u16le, v)),
      parse: &Parser.parse_du16/1
    }
  end

  def for("S16BE") do
    %{
      factor: 1,
      decode: &for(v <- &1, do: Convert.to(:s16be, v)),
      encode: &for(v <- &1, do: Convert.from(:s16be, v)),
      parse: &Parser.parse_ds16/1
    }
  end

  def for("S16LE") do
    %{
      factor: 1,
      decode: &for(v <- &1, do: Convert.to(:s16le, v)),
      encode: &for(v <- &1, do: Convert.from(:s16le, v)),
      parse: &Parser.parse_ds16/1
    }
  end

  # opto22
  def for("F32BE") do
    %{
      factor: 2,
      decode: &for(v <- Enum.chunk_every(&1, 2), do: Convert.to(:f32be, v)),
      encode: &(for(v <- &1, do: Convert.from(:f32be, v)) |> List.flatten()),
      parse: &Parser.parse_df32/1
    }
  end

  def for("F32LE") do
    %{
      factor: 2,
      decode: &for(v <- Enum.chunk_every(&1, 2), do: Convert.to(:f32le, v)),
      encode: &(for(v <- &1, do: Convert.from(:f32le, v)) |> List.flatten()),
      parse: &Parser.parse_df32/1
    }
  end
end

:ok
