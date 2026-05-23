defmodule Flex.UserScreens.VUtils do
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
      {:point, "pulse:" <> _} -> integer(change, props, params, key, {-32_768, 32_767})
      {:point, _} -> text?(change, props, params, key)
      {:point?, "bit:" <> _} -> integer(change, props, params, key, {0, 1}, true)
      {:point?, "uint16:" <> _} -> integer(change, props, params, key, {0, 65_535}, true)
      {:point?, "sint16:" <> _} -> integer(change, props, params, key, {-32_768, 32_767}, true)
      {:point?, "float:" <> _} -> float(change, props, params, key, {nil, nil}, true)
      {:point?, "status:" <> _} -> integer(change, props, params, key, {0, 3}, true)
      {:point?, "pulse:" <> _} -> integer(change, props, params, key, {-32_768, 32_767}, true)
      {:point?, _} -> text?(change, props, params, key)
    end
  end

  def errors(props) do
    Enum.map(props, fn {k, _} -> {k, nil} end) |> Enum.into(%{})
  end

  def params(props, params) do
    for({k, _} <- props, do: {k, params["#{k}"]}) |> Enum.into(%{})
  end

  def get_typed(map_or_kw, key, type) do
    valid? = valid?(type)
    value = map_or_kw[key]
    if valid?.(value), do: value
  end

  def parse_css(""), do: %{}

  def parse_css(style) do
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

  # {verbatim output, calculated taken, evaluated style}
  def eval_rt(calc, bindings, take, style) do
    with {nil, calculated} <- eval_calc(calc, bindings) do
      taken = Keyword.take(calculated, take)
      params = get_typed(calculated, :style, :keyword) || []
      {error, styled} = eval_style(style, params)
      {error || inspect(taken, pretty: true, width: 0), taken, styled}
    else
      {error, _} -> {error, [], ""}
    end
  end

  # {error string?, calculated map, taken keyword}
  def eval_calc("", bindings) do
    {nil, bindings}
  end

  def eval_calc(calc, bindings) do
    # https://www.erlang.org/doc/apps/stdlib/io_lib.html#format/2
    # search: io_lib Format Escapes
    f = fn
      f, d when is_list(d) -> :io_lib.format(f, d) |> to_string()
      f, d -> :io_lib.format(f, [d]) |> to_string()
    end

    case eval_code(calc, [{:f, f} | bindings]) do
      {{:ok, {_, kw}}, _} ->
        {nil, kw}

      {{:error, _error}, _} ->
        {"Calculator error", []}
    end
  end

  def pretty_vars(keyword) do
    keyword = Enum.filter(keyword, fn {k, v} -> !is_function(v) end)
    keyword = Enum.sort_by(keyword, fn {k, _v} -> k end)
    inspect(keyword, pretty: true, width: 0)
  end

  defp eval_style("", _) do
    {nil, ""}
  end

  defp eval_style(style, []) do
    {nil, style}
  end

  defp eval_style(style, bindings) do
    case eval_code("\"\"\"\n#{style}\n\"\"\"", bindings) do
      {{:ok, {res, _}}, _} when is_binary(res) -> {nil, res}
      {{:error, _error}, _} -> {"Style error", ""}
      {{:ok, {_res, _}}, _} -> {"Style error", ""}
    end
  end

  defp eval_code(code, bindings) do
    # with_diagnostics to silence stdio
    Code.with_diagnostics(fn ->
      try do
        {:ok, Code.eval_string(code, bindings)}
      rescue
        error -> {:error, error}
      catch
        error -> {:error, error}
      end
    end)
  end

  defp integer(change, props, params, key, {min, max}, null? \\ false) do
    tv = params |> Map.get(key) |> String.trim()
    tv = if(null? && tv == "", do: nil, else: tv)
    cv = props[key]

    case tv && Integer.parse(tv) do
      nil ->
        if(tv == cv, do: change, else: Map.put(change, key, nil))

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

  defp float(change, props, params, key, {min, max}, null? \\ false) do
    tv = params |> Map.get(key) |> String.trim()
    tv = if(null? && tv == "", do: nil, else: tv)
    cv = props[key]

    case tv && Float.parse(tv) do
      nil ->
        if(tv == cv, do: change, else: Map.put(change, key, nil))

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
