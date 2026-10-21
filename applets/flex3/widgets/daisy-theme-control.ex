defmodule Flex.DaisyThemeControl do
  use Flex.ValueControl

  # phx-update="ignore" required to keep it open
  # checked={value == (@value || @input)} is really checked={value == @input}
  # because value bubbles up but not down
  # kinda works anyway
  defp render(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index} phx-update="ignore">
      <details>
        <summary class="daisy-btn daisy-btn-sm">Theme</summary>
        <ul>
          <li :for={{value, label} <- [{"default", "Default"}, {"dark", "Dark"}, {"light", "Light"}]}>
            <input type="radio" name="payload" value={value} aria-label={label} checked={value == (@value || @input)}
              class="daisy-btn daisy-btn-sm theme-controller w-full">
          </li>
        </ul>
      </details>
    </form>
    """
  end
end
