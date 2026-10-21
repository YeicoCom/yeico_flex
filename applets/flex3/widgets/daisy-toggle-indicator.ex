defmodule Flex.DaisyToggleIndicator do
  use Flex.ValueIndicator

  defp render(assigns) do
    ~H"""
    <input id={@id} type="checkbox" tabindex="-1" class={["pointer-events-none daisy-toggle", @class]} checked={!!@value} />
    """
  end
end
