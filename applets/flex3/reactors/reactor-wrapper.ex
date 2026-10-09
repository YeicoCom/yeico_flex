defmodule Flex.ReactorWrapper do
  use Flex.Reactor

  defp initial,
    do: %{
      args: [],
      fun: nil
    }

  defp checks,
    do: %{
      args: {:list, nil, &check(&1, &2)},
      fun: {:fun, 1}
    }

  defp args(%{args: args}), do: args
  defp handler(%{fun: fun}), do: fun

  # keep in sync with reactive-logic arg check
  defp check(name, value) do
    case value do
      {key, value} ->
        Check.check(name, key, :atom)

        case value do
          {:timer, ms} -> Check.check("#{name}.timer", ms, {:integer, 1, 65_535})
          {:point, key} -> Check.check("#{name}.point", key, :any)
          {:const, _value} -> :ok
          _ -> Check.abort(name, value, "invalid arg")
        end

      _ ->
        Check.abort(name, value, "invalid arg")
    end
  end
end
