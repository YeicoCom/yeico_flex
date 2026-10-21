defmodule Flex.DaisyRangeIndicator do
  use Flex.ValueIndicator

  defp render(assigns) do
    ~H"""
    <input id={@id} :if={@visible?} type="range" min={@props.min} max={@props.max} step={@props.step} tabindex="-1" class={["pointer-events-none daisy-range", @class]} value={@value} />
    """
  end
end
