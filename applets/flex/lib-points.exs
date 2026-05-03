use Terminal

get_key = fn dir, type, name ->
  "#{dir}:#{type}:#{name}"
end

get_def = fn
  "source:float:" <> _ -> 0.0
  "sink:float:" <> _ -> 0.0
  _ -> 0
end

# FIXME float is not covered by 0 default
# default value here must cover all types below
# keys must be typed to avoid type mixing
get_value = fn key ->
  case Adb.get("flex:point:#{key}") do
    nil -> get_def.(key)
    val -> val
  end
end

put_value = fn key, val ->
  Api.putcast!("flex:point:#{key}", val)
end

subget = fn key ->
  case Api.subget!("flex:point:#{key}") do
    nil -> get_def.(key)
    val -> val
  end
end

get_sources = fn ->
  "flex:points:source"
  |> Mdb.lookup()
  |> Enum.map(fn {_, tag} -> tag end)
end

get_sinks = fn ->
  "flex:points:sink"
  |> Mdb.lookup()
  |> Enum.map(fn {_, tag} -> tag end)
end

# required to parse forms
# nil to disable check
# get_type = fn
#   :bit -> %{name: :bit, parent: :integer, min: 0, max: 1}
#   :uint16 -> %{name: :uint16, parent: :integer, min: 0x0000, max: 0xFFFF}
#   :sint16 -> %{name: :sint16, parent: :integer, min: -32_768, max: 32_767}
#   :float -> %{name: :float, parent: :float, min: nil, max: nil}
#   "bit:" <> _ -> %{name: :bit, parent: :integer, min: 0, max: 1}
#   "uint16:" <> _ -> %{name: :uint16, parent: :integer, min: 0x0000, max: 0xFFFF}
#   "sint16:" <> _ -> %{name: :sint16, parent: :integer, min: -32_768, max: 32_767}
#   "float:" <> _ -> %{name: :float, parent: :float, min: nil, max: nil}
# end

:ok
