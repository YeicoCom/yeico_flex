defmodule Flex.ValueIndicator do
  defmacro __using__(_) do
    quote do
      use Flex.Reactor
      use Terminal.Live

      defp specs, do: Flex.ValueIndicator.specs()
      defp inputs(config), do: Flex.ValueIndicator.inputs(config)
      defp handler(config), do: Flex.ValueIndicator.handler(config, &render/1, &id/1)
      defp id(index), do: "#{inspect(__MODULE__)}_#{index}"
    end
  end

  def specs,
    do: %{
      source: %{initial: nil, check: &Flex.Check.check(&1, &2, :source)},
      visible: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible?: %{initial: nil, check: {:fun?, 1}},
      text: %{initial: nil, check: :binary?},
      class: %{initial: nil, check: :binary?},
      calc: %{initial: nil, check: {:fun?, 1}},
      props: %{initial: %{}, check: :map}
    }

  def inputs(%{source: nil, visible: nil}), do: []
  def inputs(%{source: source, visible: nil}), do: [{:value, source}]
  def inputs(%{source: nil, visible: visible}), do: [{:visible, visible}]
  def inputs(%{source: source, visible: visible}), do: [{:value, source}, {:visible, visible}]

  def handler(config, render, id) do
    %{class: class, source: source, text: text} = config
    %{visible: visible, visible?: visible?} = config
    %{calc: calc, props: props} = config

    fn
      %{state: state, inputs: inputs, event: :render} ->
        visible = Flex.Reactor.input(inputs, :visible, visible)
        state = Map.put(state, :visible?, visible?(visible?, visible))
        render.(state)

      %{state: state, inputs: inputs, index: index, event: :mount} ->
        state
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:props, props)
        |> Map.put(:text, text)
        |> Map.put(:value, calc(inputs, source, calc))
        |> Map.put(:id, id.(index))

      %{state: state, inputs: inputs} ->
        state
        |> Map.put(:value, calc(inputs, source, calc))
    end
  end

  def calc(inputs, source, calc) do
    value = Flex.Reactor.input(inputs, :value, source)
    if calc, do: calc.(value), else: value
  end

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
