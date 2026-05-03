use Terminal

get = fn
  "NONE" ->
    %{
      factor: 1,
      decode: & &1,
      encode: & &1,
      parse: parser.parse_du16
    }

  "U16BE" ->
    %{
      factor: 1,
      decode: &for(v <- &1, do: convert.to.(:u16be, v)),
      encode: &for(v <- &1, do: convert.from.(:u16be, v)),
      parse: parser.parse_du16
    }

  # turck vibration and temp sensor CMVT-QR20-IOLX3-H1141
  # FIXME: confirm if such sensor encoding is actually signed
  "U16LE" ->
    %{
      factor: 1,
      decode: &for(v <- &1, do: convert.to.(:u16le, v)),
      encode: &for(v <- &1, do: convert.from.(:u16le, v)),
      parse: parser.parse_du16
    }

  "S16BE" ->
    %{
      factor: 1,
      decode: &for(v <- &1, do: convert.to.(:s16be, v)),
      encode: &for(v <- &1, do: convert.from.(:s16be, v)),
      parse: parser.parse_ds16
    }

  "S16LE" ->
    %{
      factor: 1,
      decode: &for(v <- &1, do: convert.to.(:s16le, v)),
      encode: &for(v <- &1, do: convert.from.(:s16le, v)),
      parse: parser.parse_ds16
    }

  # opto22
  "F32BE" ->
    %{
      factor: 2,
      decode: &for(v <- Enum.chunk_every(&1, 2), do: convert.to.(:f32be, v)),
      encode: &(for(v <- &1, do: convert.from.(:f32be, v)) |> List.flatten()),
      parse: parser.parse_df32
    }

  "F32LE" ->
    %{
      factor: 2,
      decode: &for(v <- Enum.chunk_every(&1, 2), do: convert.to.(:f32le, v)),
      encode: &(for(v <- &1, do: convert.from.(:f32le, v)) |> List.flatten()),
      parse: parser.parse_df32
    }
end

:ok
