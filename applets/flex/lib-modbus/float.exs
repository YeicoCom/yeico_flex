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

  {_this, :from, w0, w1, :le} ->
    <<value::float-32>> = <<w1::16, w0::16>>
    value

  {this, :to, [f | tail], endianness} ->
    [w0, w1] = this.({this, :to, f, endianness})
    [w0, w1 | this.({this, :to, tail, endianness})]

  {_this, :to, f, :be} ->
    <<w0::16, w1::16>> = <<f::float-32>>
    [w0, w1]

  {_this, :to, f, :le} ->
    <<w0::16, w1::16>> = <<f::float-32>>
    [w1, w0]
end

from_be = fn list_of_regs -> this.({this, :from, list_of_regs, :be}) end
from_le = fn list_of_regs -> this.({this, :from, list_of_regs, :le}) end
to_be = fn list_of_floats -> this.({this, :to, list_of_floats, :be}) end
to_le = fn list_of_floats -> this.({this, :to, list_of_floats, :le}) end

:ok
