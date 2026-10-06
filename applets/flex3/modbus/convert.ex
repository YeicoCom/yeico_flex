defmodule Modbus.Convert do
  # https://erlang.org/euc/00/bit_syntax.html (6.4 Defaults)
  # Erlang defaults to big-endian, unsigned, integer.
  # Modbus defaults to big-endian words

  # https://www.h-schmidt.net/FloatConverter/IEEE754.html
  # apparently <<d::float-32>> auto converts d to float (from integer and double)
  # both d=1 and d=1.0 render same <<d::float-32>>

  def to(:u16be, value) do
    value
  end

  def to(:u16le, value) do
    <<value::unsigned-little-integer-size(16)>> = <<value::size(16)>>
    value
  end

  def to(:s16be, value) do
    <<value::signed-big-integer-size(16)>> = <<value::size(16)>>
    value
  end

  def to(:s16le, value) do
    <<value::signed-little-integer-size(16)>> = <<value::size(16)>>
    value

    # erlang float does not support nan nor infinity
  end

  def to(:f32be, [0xFFFF, 0xFFFF]) do
    -3.4028235e38
  end

  def to(:f32le, [0xFFFF, 0xFFFF]) do
    -3.4028235e38
  end

  def to(:f32be, [w0, w1]) do
    <<value::big-float-32>> = <<w0::16, w1::16>>
    value
  end

  def to(:f32le, [w0, w1]) do
    # byte swap
    # <<value::little-float-32>> = <<w0::16, w1::16>>
    # reg swap
    <<value::big-float-32>> = <<w1::16, w0::16>>
    value
  end

  def from(:u16be, value) do
    value
  end

  def from(:u16le, value) do
    <<value::size(16)>> = <<value::unsigned-little-integer-size(16)>>
    value
  end

  def from(:s16be, value) do
    <<value::size(16)>> = <<value::signed-big-integer-size(16)>>
    value
  end

  def from(:s16le, value) do
    <<value::size(16)>> = <<value::signed-little-integer-size(16)>>
    value
  end

  def from(:f32be, value) do
    <<w0::16, w1::16>> = <<value::big-float-32>>
    [w0, w1]
  end

  def from(:f32le, value) do
    # byte swap
    # <<w0::16, w1::16>> = <<value::little-float-32>>
    # reg swap
    <<w1::16, w0::16>> = <<value::big-float-32>>
    [w0, w1]
  end
end
