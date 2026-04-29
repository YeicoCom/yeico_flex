use Terminal

parse = fn
  change, props, params, key, :not_empty ->
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case {tv, String.length(tv)} do
      {_, 0} -> put_in(change, [:errors, key], "Must not be empty")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end

  change, props, params, key, {:int, min, max} ->
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case Integer.parse(tv) do
      {v, _} when not is_nil(min) and v < min ->
        put_in(change, [:errors, key], "Must be >= #{min}")

      {v, _} when not is_nil(max) and v > max ->
        put_in(change, [:errors, key], "Must be <= #{max}")

      {^cv, ""} ->
        change

      {v, ""} ->
        Map.put(change, key, v)

      _ ->
        put_in(change, [:errors, key], "Must be an integer")
    end
end

errors = fn props ->
  Enum.map(props, fn {k, _} -> {k, nil} end) |> Enum.into(%{})
end

params = fn props, params ->
  for({k, _} <- props, do: {k, params["#{k}"]}) |> Enum.into(%{})
end

%{
  parse: parse,
  errors: errors,
  params: params
}
