defmodule Flex.ReactorWrapper do
  use Flex.Reactor

  defp specs,
    do: %{
      inputs: %{initial: [], check: {:list, nil, &Flex.Check.check(&1, &2, :input)}},
      handler: %{initial: nil, check: {:fun, 1}}
    }

  defp inputs(%{inputs: inputs}), do: inputs
  defp handler(%{handler: handler}), do: handler
end
