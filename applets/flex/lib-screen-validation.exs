use Terminal

parse = fn
  change, props, params, key, {:integer, min, max} ->
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

  change, props, params, key, :text ->
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case {tv, String.length(tv)} do
      {_, 0} -> put_in(change, [:errors, key], "Must not be empty")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end

  change, props, params, key, :boolean ->
    tv = params |> Map.get(key) |> String.trim() |> String.downcase()
    cv = props[key] |> to_string()

    case {tv, tv in ["true", "false"]} do
      {_, false} -> put_in(change, [:errors, key], "Must be a boolean")
      {^cv, _} -> change
      _ -> Map.put(change, key, String.to_atom(tv))
    end

  change, props, params, key, :color ->
    tv = params |> Map.get(key) |> String.trim() |> String.downcase()
    cv = props[key]

    case {tv, Regex.match?(~r/^#[A-Fa-f0-9]{6}$/, tv)} do
      {_, false} -> put_in(change, [:errors, key], "Must be hex color #rrggbb")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end

  change, props, params, key, :style ->
    tv = params |> Map.get(key) |> String.trim() |> String.downcase()
    cv = props[key]

    # single style per line only
    pairs =
      tv
      |> String.split("\n", trim: true)
      |> Enum.map(&String.replace(&1, ~r/ +/, " "))
      |> Enum.map(&String.trim(&1))
      |> Enum.map(&String.replace_suffix(&1, ";", ""))
      |> Enum.map(&String.split(&1, ":", parts: 2))

    error? =
      for pair? <- pairs, reduce: false do
        error? ->
          with [k, _] <- pair?,
               k <- String.trim(k),
               true <- Regex.match?(~r/^[a-z][a-z-]*[a-z]$/, k) do
            false
          else
            _ -> error? or true
          end
      end

    # always end with new line to match initial value with """
    tv =
      pairs
      |> Enum.map(&Enum.join(&1, ": "))
      |> Enum.map(&(&1 <> ";\n"))

    case {tv, error?} do
      {_, true} -> put_in(change, [:errors, key], "Must one style per line")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
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
