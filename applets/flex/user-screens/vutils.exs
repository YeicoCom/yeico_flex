defmodule Flex.UserScreens.VUtils do
  def inspect?(v) when is_binary(v), do: v
  def inspect?(v), do: inspect(v)

  def parse(change, props, params, key, :text) do
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case {tv, String.length(tv)} do
      {_, 0} -> put_in(change, [:errors, key], "Must not be empty")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end
  end

  def parse(change, props, params, key, :boolean) do
    tv = params |> Map.get(key) |> String.trim() |> String.downcase()
    cv = props[key] |> to_string()

    case {tv, tv in ["true", "false"]} do
      {_, false} -> put_in(change, [:errors, key], "Must be a boolean")
      {^cv, _} -> change
      _ -> Map.put(change, key, String.to_atom(tv))
    end
  end

  def parse(change, props, params, key, :color) do
    tv = params |> Map.get(key) |> String.trim() |> String.downcase()
    cv = props[key]

    case {tv, Regex.match?(~r/^#[A-Fa-f0-9]{6}$/, tv)} do
      {_, false} -> put_in(change, [:errors, key], "Must be a hex color #rrggbb")
      {^cv, _} -> change
      _ -> Map.put(change, key, tv)
    end
  end

  def parse(change, props, params, key, :style) do
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
  end

  def parse(change, props, params, key, type) do
    case type do
      :text? -> text?(change, props, params, key)
      {:integer, min, max} -> integer(change, props, params, key, {min, max})
      {:point, "bit:" <> _} -> integer(change, props, params, key, {0, 1})
      {:point, "uint16:" <> _} -> integer(change, props, params, key, {0, 65_535})
      {:point, "sint16:" <> _} -> integer(change, props, params, key, {-32_768, 32_767})
      {:point, "float:" <> _} -> float(change, props, params, key, {nil, nil})
      {:point, "status:" <> _} -> integer(change, props, params, key, {0, 3})
      {:point, _} -> text?(change, props, params, key)
    end
  end

  def errors(props) do
    Enum.map(props, fn {k, _} -> {k, nil} end) |> Enum.into(%{})
  end

  def params(props, params) do
    for({k, _} <- props, do: {k, params["#{k}"]}) |> Enum.into(%{})
  end

  def get_typed(map, key, type) do
    valid? = valid?(type)
    value = map[key]
    if valid?.(value), do: value
  end

  def get_css(""), do: %{}

  def get_css(style) do
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

  def eval_rt(calc, bindings, take, style) do
    with {:ok, output, calc} <- eval_calc(calc, bindings, take) do
      bindings = get_typed(calc, :style, :keyword) || []
      eval_style(style, bindings, output, calc)
    else
      {:error, output, calc} -> {output, calc, ""}
    end
  end

  defp eval_calc("", bindings, take) do
    {:ok, Keyword.take(bindings, take), Enum.into(bindings, %{})}
  end

  defp eval_calc(calc, bindings, take) do
    f = fn
      f, d when is_list(d) -> :io_lib.format(f, d) |> to_string()
      f, d -> :io_lib.format(f, [d]) |> to_string()
    end

    case Flex.eval_code(calc, [{:f, f} | bindings]) do
      {{:ok, {_, kw}}, _} ->
        {:ok, Keyword.take(kw, take), Enum.into(kw, %{})}

      {{:error, _error}, _} ->
        {:error, "Calculator error", %{}}
    end
  end

  defp eval_style("", _, output, calc) do
    {output, calc, ""}
  end

  defp eval_style(style, [], output, calc) do
    {output, calc, style}
  end

  defp eval_style(style, bindings, output, calc) do
    case Flex.eval_code("\"\"\"\n#{style}\n\"\"\"", bindings) do
      {{:ok, {res, _}}, _} when is_binary(res) -> {output, calc, res}
      {{:ok, {res, _}}, _} -> {[style: res], calc, ""}
      {{:error, _error}, _} -> {"Style error", calc, ""}
    end
  end

  defp integer(change, props, params, key, {min, max}) do
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

  defp float(change, props, params, key, {min, max}) do
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

  defp text?(change, props, params, key) do
    tv = params |> Map.get(key) |> String.trim()
    cv = props[key]

    case tv do
      ^cv -> change
      _ -> Map.put(change, key, tv)
    end
  end

  defp valid?(:binary) do
    fn
      v when is_binary(v) -> true
      _ -> false
    end
  end

  defp valid?(:boolean) do
    fn
      v when is_boolean(v) -> true
      _ -> false
    end
  end

  defp valid?(:keyword) do
    fn
      v when is_list(v) -> Keyword.keyword?(v)
      _ -> false
    end
  end
end

:ok
