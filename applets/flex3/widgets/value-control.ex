defmodule Flex.ValueControl do
  defmacro __using__(_) do
    quote do
      use Flex.Reactor
      use Terminal.Live

      defp specs, do: Flex.ValueControl.specs()
      defp inputs(config), do: Flex.ValueControl.inputs(config)
      defp handler(config), do: Flex.ValueControl.handler(config, &render/1, &id/1)
      defp id(index), do: "#{inspect(__MODULE__)}_#{index}"
    end
  end

  alias Applet.Api

  def specs,
    do: %{
      source: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      sink: %{initial: nil, check: &Flex.Check.check(&1, &2, :sink?)},
      visible: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible?: %{initial: nil, check: {:fun?, 1}},
      class: %{initial: nil, check: :binary?},
      cast: %{initial: nil, check: {:fun?, 1}},
      initial?: %{initial: false, check: :boolean},
      initial: %{initial: nil, check: :any?},
      props: %{initial: %{}, check: :map}
    }

  def inputs(%{source: nil, visible: nil}), do: []
  def inputs(%{source: source, visible: nil}), do: [{:value, source}]
  def inputs(%{source: nil, visible: visible}), do: [{:visible, visible}]
  def inputs(%{source: source, visible: visible}), do: [{:value, source}, {:visible, visible}]

  def handler(config, render, id) do
    %{initial?: initial?, visible: visible, visible?: visible?} = config
    %{class: class, initial: initial, props: props, source: source} = config

    fn
      %{state: state, inputs: inputs, event: :render} ->
        visible = Flex.Reactor.input(inputs, :visible, visible)
        state = Map.put(state, :visible?, visible?(visible?, visible))
        state = Map.put(state, :input, Flex.Reactor.input(inputs, :value, source))
        render.(state)

      ctx = %{index: index, event: :mount} ->
        update(ctx, config, initial, initial?)
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:props, props)
        |> Map.put(:id, id.(index))

      # checkbox wont send value param when unchecked
      # phx-value-value is special and wont get sent
      ctx = %{event: {:event, "value:change", params}} ->
        update(ctx, config, params["payload"], true)

      %{state: state} ->
        state
    end
    |> Flex.wrap()
  end

  defp update(%{state: state, share: share}, %{cast: cast, sink: sink}, value, initial?) do
    value = if cast, do: cast.(value), else: value

    if sink && initial? do
      case sink do
        {:shared, name} -> share.(name, value)
        {:point, point} -> Api.putcast!(point, value)
      end
    end

    Map.put(state, :value, value)
  end

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
