defmodule Flex.ValueIndicator do
  defmacro __using__(_) do
    quote do
      use Flex.Reactor
      use Terminal.Live

      defp specs, do: Flex.ValueIndicator.specs()
      defp inputs(config), do: Flex.ValueIndicator.inputs(config)
      defp handler(config), do: Flex.ValueIndicator.handler(config, &render/1)
    end
  end

  def specs,
    do: %{
      source: %{initial: nil, check: &Flex.Check.check(&1, &2, :source)},
      class: %{initial: nil, check: :binary?},
      calc: %{initial: nil, check: {:fun?, 1}}
    }

  def inputs(%{source: nil}), do: []
  def inputs(%{source: source}), do: [{:value, source}]

  def handler(%{class: class, source: source, calc: calc}, render) do
    fn
      %{state: state, event: :render} ->
        render.(state)

      %{state: state, inputs: inputs, index: index, event: :mount} ->
        state
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:value, calc(inputs, source, calc))

      %{state: state, inputs: inputs} ->
        state
        |> Map.put(:value, calc(inputs, source, calc))
    end
  end

  def calc(inputs, source, calc) do
    value =
      case source do
        nil -> nil
        {:const, value} -> value
        {:timer, _ms} -> inputs[:value]
        {:point, _point} -> inputs[:value]
        {:shared, _shared} -> inputs[:value]
      end

    if calc, do: calc.(value), else: value
  end
end
