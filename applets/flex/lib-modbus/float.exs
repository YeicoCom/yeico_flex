use Terminal

# https://www.h-schmidt.net/FloatConverter/IEEE754.html
this = fn
  {_this, _, [], _} ->
    []

  {this, :from, [w0, w1 | tail], endianness} ->
    [this.({this, :from, w0, w1, endianness}) | this.({this, :from, tail, endianness})]

  {_this, :from, w0, w1, :be} ->
    <<value::float-32>> = <<w0::16, w1::16>>
    value

  {_this, :from, w0, w1, :le_cdab} ->
    <<value::float-32>> = <<w1::16, w0::16>>
    value

  {_this, :from, w0, w1, :le_dcba} ->
    <<a::8, b::8>> = <<w0::size(16)>>
    <<c::8, d::8>> = <<w1::size(16)>>
    <<value::float-32>> = <<d::8, c::8, b::8, a::8>>
    value

  {this, :to, [f | tail], endianness} ->
    [w0, w1] = this.({this, :to, f, endianness})
    [w0, w1 | this.({this, :to, tail, endianness})]

  {_this, :to, f, :be} ->
    <<w0::16, w1::16>> = <<f::float-32>>
    [w0, w1]

  {_this, :to, f, :le_cdab} ->
    <<w0::16, w1::16>> = <<f::float-32>>
    [w1, w0]

  {_this, :to, f, :le_dcba} ->
    <<d::8, c::8, b::8, a::8>> = <<f::float-32>>
    <<w0::size(16)>> = <<a::8, b::8>>
    <<w1::size(16)>> = <<c::8, d::8>>
    [w0, w1]
end

from_be_abcd = fn list_of_regs -> this.({this, :from, list_of_regs, :be}) end
from_le_cdab = fn list_of_regs -> this.({this, :from, list_of_regs, :le_cdab}) end
from_le_dcba = fn list_of_regs -> this.({this, :from, list_of_regs, :le_dcba}) end
to_be_abcd = fn list_of_floats -> this.({this, :to, list_of_floats, :be}) end
to_le_cdab = fn list_of_floats -> this.({this, :to, list_of_floats, :le_cdab}) end
to_le_dcba = fn list_of_floats -> this.({this, :to, list_of_floats, :le_dcba}) end

:ok
