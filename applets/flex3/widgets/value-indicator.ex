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
      source: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible?: %{initial: nil, check: {:fun?, 1}},
      class: %{initial: nil, check: :binary?},
      cast: %{initial: nil, check: {:fun?, 1}},
      props: %{initial: %{}, check: :map}
    }

  def inputs(%{source: nil, visible: nil}), do: []
  def inputs(%{source: source, visible: nil}), do: [{:value, source}]
  def inputs(%{source: nil, visible: visible}), do: [{:visible, visible}]
  def inputs(%{source: source, visible: visible}), do: [{:value, source}, {:visible, visible}]

  def handler(config, render, id) do
    %{visible: visible, visible?: visible?} = config
    %{class: class, source: source} = config
    %{cast: cast, props: props} = config

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
        |> Map.put(:value, cast(inputs, source, cast))
        |> Map.put(:id, id.(index))

      %{state: state, inputs: inputs} ->
        state
        |> Map.put(:value, cast(inputs, source, cast))
    end
  end

  def cast(inputs, source, cast) do
    value = Flex.Reactor.input(inputs, :value, source)
    if cast, do: cast.(value), else: value
  end

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
