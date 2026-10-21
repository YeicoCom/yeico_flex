defmodule Flex.DaisyToggleControl do
  use Flex.ValueControl

  defp render(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index}>
      <input type="checkbox" name="payload" class={["daisy-toggle", @class]} checked={!!@value} />
    </form>
    """
  end
end
