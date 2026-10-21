defmodule Flex.DaisySelectControl do
  use Flex.ValueControl

  # size > 1 to workaround select closing on each phx update
  # select requires a source/@input to stay in sync
  defp render(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index}>
      <select name="payload" class={["daisy-select", @class]} size={max(2, @props[:size] || 2)}>
        <option :for={{value, label} <- @props[:options] || []} value={value} selected={value == @input}
          class={@props[:class]}>{label}</option>
      </select>
    </form>
    """
  end
end
