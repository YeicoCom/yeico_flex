defmodule Flex.DaisyButtonControl do
  use Flex.ValueControl

  defp render(assigns) do
    ~H"""
    <button id={@id} :if={@visible?} phx-click="value:change"
      phx-value-index={@index}  phx-value-payload={@value}
      class={["daisy-btn", @class]}>
      {@props.text}
    </button>
    """
  end
end
