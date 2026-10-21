defmodule Flex.Check do
  alias Applet.Api

  def check(path, value, :any) when is_nil(value), do: abort(path, value, "any required")
  def check(_path, _value, :any), do: :ok
  def check(_path, _value, :any?), do: :ok

  def check(_path, value, {:ge, limit}) when value >= limit, do: :ok

  def check(path, value, {:ge, limit}),
    do: abort(path, value, ">= #{Api.inspect?(limit)} required")

  def check(_path, value, {:le, limit}) when value <= limit, do: :ok

  def check(path, value, {:le, limit}),
    do: abort(path, value, "<= #{Api.inspect?(limit)} required")

  def check(_path, value, :integer) when is_integer(value), do: :ok
  def check(path, value, :integer), do: abort(path, value, "integer required")
  def check(_path, value, :integer?) when is_nil(value), do: :ok
  def check(_path, value, :integer?) when is_integer(value), do: :ok
  def check(path, value, :integer?), do: abort(path, value, "integer? required")

  def check(path, value, {:integer, min, max}) do
    check(path, value, :integer)
    check("#{path}.min", min, :integer?)
    check("#{path}.max", max, :integer?)
    if min, do: check(path, value, {:ge, min})
    if max, do: check(path, value, {:le, max})
  end

  def check(_path, value, :float) when is_float(value), do: :ok
  def check(path, value, :float), do: abort(path, value, "float required")
  def check(_path, value, :float?) when is_nil(value), do: :ok
  def check(_path, value, :float?) when is_float(value), do: :ok
  def check(path, value, :float?), do: abort(path, value, "float? required")

  def check(path, value, {:float, min, max}) do
    check(path, value, :float)
    check("#{path}.min", min, :float?)
    check("#{path}.max", max, :float?)
    if min, do: check(path, value, {:ge, min})
    if max, do: check(path, value, {:le, max})
  end

  def check(_path, value, :number) when is_number(value), do: :ok
  def check(path, value, :number), do: abort(path, value, "number required")
  def check(_path, value, :number?) when is_nil(value), do: :ok
  def check(_path, value, :number?) when is_number(value), do: :ok
  def check(path, value, :number?), do: abort(path, value, "number? required")

  def check(path, value, {:number, min, max}) do
    check(path, value, :number)
    check("#{path}.min", min, :number?)
    check("#{path}.max", max, :number?)
    if min, do: check(path, value, {:ge, min})
    if max, do: check(path, value, {:le, max})
  end

  def check(_path, value, :binary) when is_binary(value), do: :ok
  def check(path, value, :binary), do: abort(path, value, "binary required")
  def check(_path, value, :binary?) when is_nil(value), do: :ok
  def check(_path, value, :binary?) when is_binary(value), do: :ok
  def check(path, value, :binary?), do: abort(path, value, "binary? required")

  def check(_path, value, :boolean) when is_boolean(value), do: :ok
  def check(path, value, :boolean), do: abort(path, value, "boolean required")
  def check(_path, value, :boolean?) when is_nil(value), do: :ok
  def check(_path, value, :boolean?) when is_boolean(value), do: :ok
  def check(path, value, :boolean?), do: abort(path, value, "boolean? required")

  def check(_path, value, :atom) when is_atom(value) and not is_nil(value), do: :ok
  def check(path, value, :atom), do: abort(path, value, "atom required")
  def check(_path, value, :atom?) when is_nil(value), do: :ok
  def check(_path, value, :atom?) when is_atom(value), do: :ok
  def check(path, value, :atom?), do: abort(path, value, "atom? required")

  def check(_path, value, :map) when is_map(value), do: :ok
  def check(path, value, :map), do: abort(path, value, "map required")
  def check(_path, value, :map?) when is_nil(value), do: :ok
  def check(_path, value, :map?) when is_map(value), do: :ok
  def check(path, value, :map?), do: abort(path, value, "map? required")

  def check(path, value, {:in, list}) do
    if value not in list do
      abort(path, value, "not in #{Api.inspect?(list)}")
    end
  end

  def check(_path, value, :list) when is_list(value), do: :ok
  def check(path, value, :list), do: abort(path, value, "list required")
  def check(_path, value, :list?) when is_nil(value), do: :ok
  def check(_path, value, :list?) when is_list(value), do: :ok
  def check(path, value, :list?), do: abort(path, value, "list? required")

  def check(_path, value, {:list, n}) when is_list(value) and length(value) == n, do: :ok
  def check(path, value, {:list, n}), do: abort(path, value, "list#{n} required")
  def check(_path, value, {:list?, _n}) when is_nil(value), do: :ok
  def check(_path, value, {:list?, n}) when is_list(value) and length(value) == n, do: :ok
  def check(path, value, {:list?, n}), do: abort(path, value, "list#{n}? required")

  def check(path, value, {:list, len, check}) do
    check(path, value, if(len, do: {:list, len}, else: :list))

    for {item, i} <- Enum.with_index(value) do
      check("#{path}[#{i}]", item, check)
    end
  end

  def check(path, value, {:list?, len, check}) do
    check(path, value, if(len, do: {:list?, len}, else: :list?))

    for {item, i} <- Enum.with_index(value || []) do
      check("#{path}[#{i}]", item, check)
    end
  end

  def check(_path, value, :tuple) when is_tuple(value), do: :ok
  def check(path, value, :tuple), do: abort(path, value, "tuple required")
  def check(_path, value, :tuple?) when is_nil(value), do: :ok
  def check(_path, value, :tuple?) when is_tuple(value), do: :ok
  def check(path, value, :tuple?), do: abort(path, value, "tuple? required")

  def check(_path, value, {:tuple, n}) when is_tuple(value) and tuple_size(value) == n, do: :ok
  def check(path, value, {:tuple, n}), do: abort(path, value, "tuple#{n} required")
  def check(_path, value, {:tuple?, _n}) when is_nil(value), do: :ok
  def check(_path, value, {:tuple?, n}) when is_tuple(value) and tuple_size(value) == n, do: :ok
  def check(path, value, {:tuple?, n}), do: abort(path, value, "tuple#{n}? required")

  def check(path, value, {:tuple, len, check}) do
    check(path, value, if(len, do: {:tuple, len}, else: :tuple))

    for {item, i} <- Enum.with_index(Tuple.to_list(value)) do
      check("#{path}[#{i}]", item, check)
    end
  end

  def check(path, value, {:tuple?, len, check}) do
    check(path, value, if(len, do: {:tuple?, len}, else: :tuple?))

    for {item, i} <- Enum.with_index(Tuple.to_list(value || {})) do
      check("#{path}[#{i}]", item, check)
    end
  end

  def check(path, value, {:starts_with?, prefix}) do
    check(path, value, :binary)
    if !String.starts_with?(value, prefix), do: abort(path, value, "prefix #{prefix} required")
  end

  def check(_path, value, {:fun, n}) when is_function(value, n), do: :ok
  def check(path, value, {:fun, n}), do: abort(path, value, "fun#{n} required")
  def check(_path, value, {:fun?, _n}) when is_nil(value), do: :ok
  def check(_path, value, {:fun?, n}) when is_function(value, n), do: :ok
  def check(path, value, {:fun?, n}), do: abort(path, value, "fun#{n}? required")

  def check(_path, nil, :sink?), do: :ok
  def check(path, value, :sink?), do: check(path, value, :sink)

  def check(path, value, :sink) do
    check(path, value, {:tuple, 2})

    case value do
      {:shared, name} -> check("#{path}.shared", name, :atom)
      {:point, name} -> check("#{path}.point", name, :any)
      _ -> abort(path, value, "invalid sink")
    end
  end

  def check(path, value, :source) do
    check(path, value, {:tuple, 2})

    case value do
      {:timer, ms} -> check("#{path}.timer", ms, {:integer, 1, 65_535})
      {:shared, name} -> check("#{path}.shared", name, :atom)
      {:point, name} -> check("#{path}.point", name, :any)
      {:const, _value} -> :ok
      _ -> abort(path, value, "invalid source")
    end
  end

  def check(_path, nil, :source?), do: :ok
  def check(path, value, :source?), do: check(path, value, :source)

  def check(path, value, :input) do
    check(path, value, {:tuple, 2})
    {name, source} = value
    check("#{path}.name", name, :atom)
    check("#{path}.source", source, :source)
  end

  # extensions
  def check(path, value, fun) when is_function(fun, 2), do: fun.(path, value)

  # required by extensions
  def abort(path, value, error) do
    throw(%{
      path: path,
      value: value,
      error: error
    })
  end
end
