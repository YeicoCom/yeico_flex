use Terminal

get_key = fn dir, type, name ->
  "#{dir}:#{type}:#{name}"
end

get_tag = fn type, name ->
  "#{type}:#{name}"
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

subget_value = fn key ->
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

capture = fn
  :uint16 -> %{step: 1, min: 0, max: 65_535}
  :sint16 -> %{step: 1, min: -32_768, max: 32_767}
  :float -> %{step: "any", min: nil, max: nil}
  :bit -> %{step: 1, min: 0, max: 1}
end

:ok
