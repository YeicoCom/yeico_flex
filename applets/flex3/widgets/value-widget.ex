defmodule Flex.ValueWidget do
  use Flex.Reactor
  use Terminal.Live

  defp specs(),
    do: %{
      visible: %{initial: nil, check: :source?},
      source: %{initial: nil, check: :source?},
      sink: %{initial: nil, check: :sink?},
      visible?: %{initial: nil, check: {:fun?, 1}},
      render: %{initial: nil, check: {:fun, 1}},
      class: %{initial: nil, check: :binary?},
      ocast: %{initial: nil, check: {:fun?, 1}},
      icast: %{initial: nil, check: {:fun?, 1}},
      oinitial?: %{initial: false, check: :boolean},
      oinitial: %{initial: nil, check: :any?},
      props: %{initial: %{}, check: :map}
    }

  defp inputs(%{source: source, sink: sink, visible: visible}) do
    [{:ivalue, source || sink}, {:visible, visible}]
    |> Enum.filter(fn {_name, spec} -> !is_nil(spec) end)
  end

  defp handler(config) do
    %{oinitial?: oinitial?, oinitial: oinitial, visible?: visible?} = config
    %{props: props, sink: sink, ocast: ocast, icast: icast} = config
    %{class: class, render: render} = config

    # only ocast on mount initialization and on value:change user action
    # state.ovalue is used to set state so ocast output must be html compatible
    update = fn ctx, ovalue, oinitial?, ocast? ->
      %{state: state, share: share, inputs: inputs} = ctx
      ovalue = if ocast? && ocast, do: ocast.(ovalue), else: ovalue
      state = Map.put(state, :ovalue, ovalue)
      ivalue = inputs[:ivalue]
      ivalue = if icast, do: icast.(ivalue), else: ivalue
      state = Map.put(state, :ivalue, ivalue)
      visible? = visible?(visible?, inputs[:visible])
      state = Map.put(state, :visible?, visible?)
      state = Map.put(state, :sink?, !!sink)

      if sink && oinitial? do
        case sink do
          {:shared, name} -> share.(name, ovalue)
          {:point, point} -> Api.putcast!(point, ovalue)
        end
      end

      state
    end

    fn
      # using wrapper captured while adding to the screen
      %{state: state, event: :render} ->
        render.(state)

      ctx = %{index: index, event: :mount} ->
        update.(ctx, oinitial, oinitial?, true)
        |> Map.put(:id, id(index, render))
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:props, props)

      # checkbox wont send value param when unchecked
      # phx-value-value is special and wont get sent
      ctx = %{event: {:event, "value:change", params}} ->
        update.(ctx, params["ovalue"], true, true)

      ctx = %{state: %{ovalue: ovalue}} ->
        update.(ctx, ovalue, false, false)
    end
  end

  defp id(index, nil), do: "#{inspect(__MODULE__)}_#{index}"

  defp id(index, render) do
    {:module, mod} = Function.info(render, :module)
    {:name, fun} = Function.info(render, :name)

    case mod do
      :erl_eval -> "#{inspect(__MODULE__)}_#{index}"
      _ -> "#{inspect(mod)}.#{fun}_#{index}"
    end
  end

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
