defmodule Flex.DaisyLabelIndicator do
  use Flex.ValueIndicator

  defp render(assigns) do
    ~H"""
    <div id={@id} :if={@visible?} tabindex="-1" class={["pointer-events-none", @class]}>
      {@value}
    </div>
    """
  end
end
