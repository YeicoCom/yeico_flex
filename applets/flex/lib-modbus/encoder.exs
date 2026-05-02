use Terminal

# https://erlang.org/euc/00/bit_syntax.html (6.4 Defaults)
# Erlang defaults to big-endian, unsigned, integer.
switch16 = fn value ->
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
      parse: parser.parse_du16
    }

  # opto22
  "F32BE" ->
    %{
      rf: 2,
      set: fn d -> float.to_be_abcd.(d) end,
      get: fn d -> float.from_be_abcd.(d) end,
      parse: parser.parse_df32
    }

  "F32LE" ->
    %{
      rf: 2,
      set: fn d -> float.to_le_dcba.(d) end,
      get: fn d -> float.from_le_dcba.(d) end,
      parse: parser.parse_df32
    }

  "U16BE" ->
    %{
      rf: 1,
      set: & &1,
      get: & &1,
      parse: parser.parse_du16
    }

  # turck vibration and temp sensor CMVT-QR20-IOLX3-H1141
  "U16LE" ->
    %{
      rf: 1,
      set: &for(v <- &1, do: switch16.(v)),
      get: &for(v <- &1, do: switch16.(v)),
      parse: parser.parse_du16
    }
end

:ok
