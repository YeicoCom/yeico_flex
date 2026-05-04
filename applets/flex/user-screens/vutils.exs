use Terminal

inspect? = fn
  v when is_binary(v) -> v
  v -> inspect(v)
end

valid? = fn
  :binary ->
    fn
      v when is_binary(v) -> true
      _ -> false
    end

  :boolean ->
    fn
      v when is_boolean(v) -> true
      _ -> false
    end

  :keyword ->
    fn
      v when is_list(v) -> Keyword.keyword?(v)
      _ -> false
    end
end

get = fn map, key, type ->
  valid? = valid?.(type)
  value = map[key]
  if valid?.(value), do: value
end

integer = fn change, props, params, key, {min, max} ->
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

float = fn change, props, params, key, {min, max} ->
  tv = params |> Map.get(key) |> String.trim()
  cv = props[key]

  case Float.parse(tv) do
    {v, _} when not is_nil(min) and v < min ->
      put_in(change, [:errors, key], "Must be >= #{min}")

    {v, _} when not is_nil(max) and v > max ->
      put_in(change, [:errors, key], "Must be <= #{max}")

    {^cv, ""} ->
      change

    {v, ""} ->
      Map.put(change, key, v)

    _ ->
      put_in(change, [:errors, key], "Must be a number")
  end
end

any = fn change, props, params, key ->
  tv = params |> Map.get(key) |> String.trim()
  cv = props[key]

  case tv do
    ^cv -> change
    _ -> Map.put(change, key, tv)
  end
end

parse = fn
  change, props, params, key, {:integer, min, max} ->
    integer.(change, props, params, key, {min, max})

  change, props, params, key, :text ->
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case {tv, String.length(tv)} do
      {_, 0} -> put_in(change, [:errors, key], "Must not be empty")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end

  change, props, params, key, :any ->
    any.(change, props, params, key)

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
      {_, false} -> put_in(change, [:errors, key], "Must be a hex color #rrggbb")
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
      |> Enum.map(&String.split(&1, ": ", parts: 2))

    error? =
      for pair? <- pairs, reduce: false do
        error? ->
          with [k, v] <- pair?,
               k <- String.trim(k),
               v <- String.trim(v),
               true <- String.length(v) > 0,
               true <- Regex.match?(~r/^[a-z][a-z-]*[a-z](:[a-z][a-z-]*[a-z])?$/, k),
               true <- Regex.match?(~r/^[^;]+$/, v) do
            error?
          else
            _ -> true
          end
      end

    # always end with new line to match initial value with """
    tv =
      pairs
      |> Enum.map(fn list -> Enum.map(list, &String.trim/1) end)
      |> Enum.map(&(Enum.join(&1, ": ") <> ";\n"))
      |> Enum.join("")

    case {tv, error?} do
      {_, true} -> put_in(change, [:errors, key], "Must be one style per line")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end

  change, props, params, key, {:point, "bit:" <> _} ->
    integer.(change, props, params, key, {0, 1})

  change, props, params, key, {:point, "uint16:" <> _} ->
    integer.(change, props, params, key, {0, 65_535})

  change, props, params, key, {:point, "sint16:" <> _} ->
    integer.(change, props, params, key, {-32_768, 32_767})

  change, props, params, key, {:point, "float:" <> _} ->
    float.(change, props, params, key, {nil, nil})

  change, props, params, key, {:point, _} ->
    any.(change, props, params, key)
end

errors = fn props ->
  Enum.map(props, fn {k, _} -> {k, nil} end) |> Enum.into(%{})
end

params = fn props, params ->
  for({k, _} <- props, do: {k, params["#{k}"]}) |> Enum.into(%{})
end

css = fn style ->
  for line <- String.split(style, "\n", trim: true), reduce: %{} do
    css ->
      [k, v] = String.split(line, ": ", parts: 2)

      case String.split(k, ":", parts: 2) do
        [k] -> Map.update(css, nil, ["#{k}: #{v}"], &["#{k}: #{v}" | &1])
        [p, k] -> Map.update(css, p, ["#{k}: #{v}"], &["#{k}: #{v}" | &1])
      end
  end
  |> Enum.map(fn {k, v} -> {k, Enum.reverse(v)} end)
  |> Enum.map(fn {k, v} -> {k, Enum.join(v, " ")} end)
  |> Enum.into(%{})
end

eval = fn calc, bindings, take, style ->
  f = fn
    f, d when is_list(d) -> :io_lib.format(f, d) |> to_string()
    f, d -> :io_lib.format(f, [d]) |> to_string()
  end

  eval_calc = fn ->
    case Api.safe(fn -> Code.eval_string(calc, [{:f, f} | bindings]) end) do
      {:ok, {_, kw}} ->
        {:ok, Keyword.take(kw, take), Enum.into(kw, %{})}

      {:error, _error} ->
        {:error, "Calculator error", %{}}
    end
  end

  with {:ok, output, calc} <- eval_calc.() do
    bindings = get.(calc, :style, :keyword) || []

    case Api.safe(fn -> Code.eval_string("\"\"\"\n#{style}\n\"\"\"", bindings) end) do
      {:ok, {res, _}} when is_binary(res) -> {output, calc, res}
      {:ok, {res, _}} -> {[style: res], calc, ""}
      {:error, _error} -> {"Style error", calc, ""}
    end
  else
    {:error, output, calc} -> {output, calc, ""}
  end
end

:ok
