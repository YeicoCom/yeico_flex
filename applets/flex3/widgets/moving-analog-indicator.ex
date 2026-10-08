defmodule Flex.MovingAnalogIndicator do
  use Flex.Widget
  use Terminal.Live

  defp initial,
    do: %{
      bar: nil
    }

  defp checks,
    do: %{
      bar: {:tuple, 2, {:integer, 0, 65_535}}
    }

  defp args(_config) do
    []
  end

  defp handler(%{bar: {bw, bh}}) do
    fn
      %{event: :render} ->
        assigns = %{bw: bw, bh: bh}

        ~H"""
        <div class={"bg-black"} style={"width:#{@bw}px;height:#{@bh}px"}></div>
        """

      %{state: state, index: index, event: event, trace: trace, global: %{connected?: connected?}} ->
        trace.(index: index, event: event, connected?: connected?)
        state
    end
  end
end
