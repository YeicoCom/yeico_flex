use Terminal

# https://erlang.org/euc/00/bit_syntax.html (6.4 Defaults)
# Erlang defaults to big-endian, unsigned, integer.
# Modbus defaults to big-endian words

# https://www.h-schmidt.net/FloatConverter/IEEE754.html
# apparently <<d::float-32>> auto converts d to float (from integer and double)
# both d=1 and d=1.0 render same <<d::float-32>>

to = fn
  :u16be, value ->
    value

  :u16le, value ->
    <<value::unsigned-little-integer-size(16)>> = <<value::size(16)>>
    value

  :s16be, value ->
    <<value::signed-big-integer-size(16)>> = <<value::size(16)>>
    value

  :s16le, value ->
    <<value::signed-little-integer-size(16)>> = <<value::size(16)>>
    value

  # erlang float does not support nan nor infinity
  :f32be, [0xFFFF, 0xFFFF] ->
    -3.4028235e38

  :f32le, [0xFFFF, 0xFFFF] ->
    -3.4028235e38

  :f32be, [w0, w1] ->
    <<value::big-float-32>> = <<w0::16, w1::16>>
    value

  :f32le, [w0, w1] ->
    # byte swap
    # <<value::little-float-32>> = <<w0::16, w1::16>>
    # reg swap
    <<value::big-float-32>> = <<w1::16, w0::16>>
    value
end

from = fn
  :u16be, value ->
    value

  :u16le, value ->
    <<value::size(16)>> = <<value::unsigned-little-integer-size(16)>>
    value

  :s16be, value ->
    <<value::size(16)>> = <<value::signed-big-integer-size(16)>>
    value

  :s16le, value ->
    <<value::size(16)>> = <<value::signed-little-integer-size(16)>>
    value

  :f32be, value ->
    <<w0::16, w1::16>> = <<value::big-float-32>>
    [w0, w1]

  :f32le, value ->
    # byte swap
    # <<w0::16, w1::16>> = <<value::little-float-32>>
    # reg swap
    <<w1::16, w0::16>> = <<value::big-float-32>>
    [w0, w1]
end

:ok
