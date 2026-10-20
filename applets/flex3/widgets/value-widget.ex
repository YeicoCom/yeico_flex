defmodule Flex.ValueWidget do
  defmacro __using__(_) do
    quote do
      use Flex.Reactor
      use Terminal.Live

      defp specs, do: Flex.ValueWidget.specs()
      defp inputs(config), do: Flex.ValueWidget.inputs(config)
      defp handler(config), do: Flex.ValueWidget.handler(config, &render/1)
    end
  end

  def specs,
    do: %{
      source: %{initial: nil, check: &Flex.Check.check(&1, &2, :source)},
      class: %{initial: nil, check: :binary?},
      calc: %{initial: nil, check: {:fun?, 2}}
    }

  def inputs(%{source: {:timer, ms}}), do: [{:value, {:timer, ms}}]
  def inputs(%{source: {:point, key}}), do: [{:value, {:point, key}}]
  def inputs(%{source: {:shared, key}}), do: [{:value, {:shared, key}}]
  def inputs(_), do: []

  def handler(config, render) do
    fn
      %{state: state, event: :render} -> render.(state)
      ctx -> update(config, ctx)
    end
  end

  def update(%{source: source, calc: calc, class: class}, ctx = %{state: state}) do
    value = calc(source, calc, ctx)
    state = Map.put(state, :value, value)
    state = Map.put(state, :class, class)
    state
  end

  def calc(source, calc, ctx = %{inputs: inputs}) do
    value =
      case source do
        nil -> nil
        {:const, value} -> value
        {:point, _point} -> inputs[:value]
        {:timer, _ms} -> inputs[:value]
        {:shared, _shared} -> inputs[:value]
      end

    if calc, do: calc.(ctx, value), else: value
  end
end
