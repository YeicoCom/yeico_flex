defmodule Flex.DaisyToggleInput do
  use Flex.ValueWidget

  defp render(assigns) do
    ~H"""
    <input type="checkbox" tabindex="-1" class={["pointer-events-none daisy-toggle", @class]} checked={!!@value} />
    """
  end
end
