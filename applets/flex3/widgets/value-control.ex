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
      sink: %{initial: nil, check: &Flex.Check.check(&1, &2, :sink)},
      visible: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible?: %{initial: nil, check: {:fun?, 1}},
      class: %{initial: nil, check: :binary?},
      calc: %{initial: nil, check: {:fun?, 1}},
      initial: %{initial: nil, check: :binary?},
      props: %{initial: %{}, check: :map}
    }

  def inputs(%{visible: nil}), do: []
  def inputs(%{visible: visible}), do: [{:visible, visible}]

  def handler(config, render, id) do
    %{visible: visible, visible?: visible?} = config
    %{class: class, initial: initial, props: props} = config

    fn
      %{state: state, inputs: inputs, event: :render} ->
        visible = Flex.Reactor.input(inputs, :visible, visible)
        visible? = visible?(visible?, visible)
        state = Map.put(state, :visible?, visible?)
        render.(state)

      ctx = %{index: index, event: :mount} ->
        update(ctx, config, initial)
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:props, props)
        |> Map.put(:id, id.(index))

      # checkbox wont send value param
      ctx = %{event: {:event, "value:change", params}} ->
        update(ctx, config, params["value"])

      %{state: state} ->
        state
    end
  end

  defp update(%{state: state, share: share}, %{calc: calc, sink: sink}, value) do
    value = if calc, do: calc.(value), else: value

    case sink do
      {:shared, name} -> share.(name, value)
      {:point, point} -> Api.putcast!(point, value)
    end

    Map.put(state, :value, value)
  end

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
