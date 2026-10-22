defmodule Flex.SparkWidget do
  use Flex.Reactor
  use Terminal.Live

  # https://github.com/mariusGundersen/sparkline
  # https://github.com/mariusGundersen/sparkline/blob/909da5007d1c46a35b17a4911dbfb40dc0f8ca3b/source/sparkline.js#L40
  def specs,
    do: %{
      visible: %{initial: nil, check: :source?},
      source: %{initial: nil, check: :source?},
      visible?: %{initial: nil, check: {:fun?, 1}},
      icast: %{initial: nil, check: {:fun?, 1}},
      maxlen: %{initial: 25, check: :integer},
      class: %{initial: nil, check: :binary?},
      props: %{initial: %{}, check: :map}
    }

  def inputs(%{source: nil}), do: [{:ivalue, {:const, []}}]
  def inputs(%{source: source}), do: [{:ivalue, source}]

  def handler(config) do
    %{props: props, class: class, visible?: visible?} = config
    %{maxlen: maxlen, icast: icast} = config
    [{_, {type, _}}] = inputs(config)

    fn
      %{state: state, inputs: inputs, event: :render} ->
        visible? = visible?(visible?, inputs[:visible])
        assigns = Map.put(state, :visible?, visible?)

        ~H"""
          <div id={@id} :if={@visible?} {@props} data-index={@index} data-maxlen={@maxlen}
            phx-hook="Spark" tabindex="-1" class={["pointer-events-none", @class]}
            phx-update="ignore" data-set={inspect?(@ivalue)}/>
        """

      %{state: state, inputs: %{ivalue: ivalue}, event: :mount, index: index} ->
        ivalue =
          cond do
            # from const, not casted
            is_list(ivalue) ->
              ivalue

            is_nil(ivalue) ->
              []

            true ->
              ivalue = if icast, do: icast.(ivalue), else: ivalue
              [ivalue]
          end

        state
        |> Map.put(:id, id(index))
        |> Map.put(:index, index)
        |> Map.put(:class, class)
        |> Map.put(:props, props)
        |> Map.put(:maxlen, maxlen)
        |> Map.put(:ivalue, ivalue)

      # do not accumulate server side
      %{
        state: state,
        inputs: %{ivalue: ivalue},
        event: {^type, :ivalue},
        index: index,
        push: push
      } ->
        ivalue = if icast, do: icast.(ivalue), else: ivalue
        push.("spark:add", %{index: index, chunk: [ivalue]})
        state

      %{state: state} ->
        state
    end
  end

  defp id(index), do: "#{inspect(__MODULE__)}_#{index}"

  # prevent ~c charlists
  defp inspect?(term),
    do:
      inspect(term,
        limit: :infinity,
        width: :infinity,
        charlists: :as_lists,
        printable_limit: :infinity
      )

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
