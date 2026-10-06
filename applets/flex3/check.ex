defmodule Flex.Check do
  alias Applet.Api

  def check(name, value, :any) when is_nil(value), do: abort(name, value, "any required")
  def check(_name, _value, :any), do: :ok
  def check(_name, _value, :any?), do: :ok

  def check(_name, value, {:ge, limit}) when value >= limit, do: :ok

  def check(name, value, {:ge, limit}),
    do: abort(name, value, ">= #{Api.inspect?(limit)} required")

  def check(_name, value, {:le, limit}) when value <= limit, do: :ok

  def check(name, value, {:le, limit}),
    do: abort(name, value, "<= #{Api.inspect?(limit)} required")

  def check(_name, value, :integer) when is_integer(value), do: :ok
  def check(name, value, :integer), do: abort(name, value, "integer required")
  def check(_name, value, :integer?) when is_nil(value), do: :ok
  def check(_name, value, :integer?) when is_integer(value), do: :ok
  def check(name, value, :integer?), do: abort(name, value, "integer? required")

  def check(name, value, {:integer, min, max}) do
    check(name, value, :integer)
    check("#{name}:min", min, :integer?)
    check("#{name}:max", max, :integer?)
    if min, do: check(name, value, {:ge, min})
    if max, do: check(name, value, {:le, max})
  end

  def check(_name, value, :float) when is_float(value), do: :ok
  def check(name, value, :float), do: abort(name, value, "float required")
  def check(_name, value, :float?) when is_nil(value), do: :ok
  def check(_name, value, :float?) when is_float(value), do: :ok
  def check(name, value, :float?), do: abort(name, value, "float? required")

  def check(name, value, {:float, min, max}) do
    check(name, value, :float)
    check("#{name}:min", min, :float?)
    check("#{name}:max", max, :float?)
    if min, do: check(name, value, {:ge, min})
    if max, do: check(name, value, {:le, max})
  end

  def check(_name, value, :binary) when is_binary(value), do: :ok
  def check(name, value, :binary), do: abort(name, value, "binary required")
  def check(_name, value, :binary?) when is_nil(value), do: :ok
  def check(_name, value, :binary?) when is_binary(value), do: :ok
  def check(name, value, :binary?), do: abort(name, value, "binary? required")

  def check(_name, value, :boolean) when is_boolean(value), do: :ok
  def check(name, value, :boolean), do: abort(name, value, "boolean required")
  def check(_name, value, :boolean?) when is_nil(value), do: :ok
  def check(_name, value, :boolean?) when is_boolean(value), do: :ok
  def check(name, value, :boolean?), do: abort(name, value, "boolean? required")

  def check(_name, value, :atom) when is_atom(value) and not is_nil(value), do: :ok
  def check(name, value, :atom), do: abort(name, value, "atom required")
  def check(_name, value, :atom?) when is_nil(value), do: :ok
  def check(_name, value, :atom?) when is_atom(value), do: :ok
  def check(name, value, :atom?), do: abort(name, value, "atom? required")

  def check(_name, value, :map) when is_map(value), do: :ok
  def check(name, value, :map), do: abort(name, value, "map required")
  def check(_name, value, :map?) when is_nil(value), do: :ok
  def check(_name, value, :map?) when is_map(value), do: :ok
  def check(name, value, :map?), do: abort(name, value, "map? required")

  def check(name, value, {:in, list}) do
    if value not in list do
      abort(name, value, "not in #{Api.inspect?(list)}")
    end
  end

  def check(_name, value, :list) when is_list(value), do: :ok
  def check(name, value, :list), do: abort(name, value, "list required")
  def check(_name, value, :list?) when is_nil(value), do: :ok
  def check(_name, value, :list?) when is_list(value), do: :ok
  def check(name, value, :list?), do: abort(name, value, "list? required")

  def check(_name, value, {:list, n}) when is_list(value) and length(value) == n, do: :ok
  def check(name, value, {:list, n}), do: abort(name, value, "list#{n} required")
  def check(_name, value, {:list?, _n}) when is_nil(value), do: :ok
  def check(_name, value, {:list?, n}) when is_list(value) and length(value) == n, do: :ok
  def check(name, value, {:list?, n}), do: abort(name, value, "list#{n}? required")

  def check(name, value, {:list, len, param}) do
    check(name, value, if(len, do: {:list, len}, else: :list))

    for {item, i} <- Enum.with_index(value) do
      check("#{name}[#{i}]", item, param)
    end
  end

  def check(name, value, {:list?, len, param}) do
    check(name, value, if(len, do: {:list?, len}, else: :list?))

    for {item, i} <- Enum.with_index(value || []) do
      check("#{name}[#{i}]", item, param)
    end
  end

  def check(name, value, {:starts_with?, prefix}) do
    check(name, value, :binary)
    if !String.starts_with?(value, prefix), do: abort(name, value, "prefix #{prefix} required")
  end

  def check(_name, value, {:fun, n}) when is_function(value, n), do: :ok
  def check(name, value, {:fun, n}), do: abort(name, value, "fun#{n} required")
  def check(_name, value, {:fun?, _n}) when is_nil(value), do: :ok
  def check(_name, value, {:fun?, n}) when is_function(value, n), do: :ok
  def check(name, value, {:fun?, n}), do: abort(name, value, "fun#{n}? required")

  # extensions
  def check(name, value, fun) when is_function(fun, 2), do: fun.(name, value)

  # required by extensions
  def abort(name, value, error) do
    throw(%{
      property: name,
      value: value,
      error: error
    })
  end
end
