defmodule Flex.DaisyRangeControl do
  use Flex.ValueControl

  defp render(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index}>
      <input name="payload" type="range" min={@props.min} max={@props.max} step={@props.step} class={["daisy-range", @class]} value={@value} />
    </form>
    """
  end
end
