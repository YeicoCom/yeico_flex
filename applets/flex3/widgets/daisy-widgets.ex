defmodule Flex.DaisyWidgets do
  use Terminal.Live

  def label(assigns) do
    ~H"""
    <div id={@id} :if={@visible?} tabindex="-1" class={["pointer-events-none", @class]}>
      {@ivalue}
    </div>
    """
  end

  def button(assigns) do
    ~H"""
    <button id={@id} :if={@visible?} phx-click="value:change"
      phx-value-index={@index}  phx-value-ovalue={@ovalue}
      class={["daisy-btn", @class]}>
      {@props[:text]}
    </button>
    """
  end

  # size > 1 to workaround select closing on each phx update
  # select requires a source/@ivalue to stay in sync
  def select(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index}>
      <select name="ovalue" class={["daisy-select", @class]} size={max(2, @props[:size] || 2)}>
        <option :for={{value, label} <- @props[:options] || []} value={value} selected={value == @ivalue}
          class={@props[:oclass]}>{label}</option>
      </select>
    </form>
    """
  end

  def toggle(assigns) do
    ~H"""
    <form id={@id} :if={@visible? and @sink?} phx-change="value:change" phx-value-index={@index}>
      <input type="checkbox" name="ovalue" class={["daisy-toggle", @class]} checked={@ovalue}/>
    </form>
    <input id={@id} :if={@visible? and !@sink?} type="checkbox" tabindex="-1" class={["pointer-events-none daisy-toggle", @class]} checked={@ivalue}/>
    """
  end

  def range(assigns) do
    ~H"""
    <form id={@id} :if={@visible? and @sink?} phx-change="value:change" phx-value-index={@index}>
      <input name="ovalue" type="range" min={@props.min} max={@props.max} step={@props.step}
        class={["daisy-range", @class]} value={@ovalue}/>
    </form>
    <input id={@id} :if={@visible? and !@sink?} type="range" min={@props.min} max={@props.max} step={@props.step}
      tabindex="-1" class={["pointer-events-none daisy-range", @class]} value={@ivalue}/>
    """
  end

  def progress(assigns) do
    ~H"""
    <progress id={@id} :if={@visible? and @props[:type] != :radial} tabindex="-1" max={@props.max}
      class={["pointer-events-none daisy-progress", @class]} value={@ivalue}/>
    <div id={@id} :if={@visible? and @props[:type] == :radial}  class={["pointer-events-none daisy-radial-progress", @class]}
      style={["--value:#{@ivalue};", @props[:size] && "--size:#{@props[:size]};", @props[:thickness] && "--thickness:#{@props[:thickness]};"]
        |> Enum.filter(& &1 != nil) |> Enum.join("")}
      >{@ivalue}%</div>
    """
  end

  # phx-update="ignore" required to keep it open
  # checked={value == (@ovalue || @ivalue)} is really checked={value == @ivalue}
  # because value bubbles up but not down
  # kinda works anyway
  def theme(assigns) do
    ~H"""
    <form id={@id} :if={@visible?} phx-change="value:change" phx-value-index={@index} phx-update="ignore">
      <details>
        <summary class={["daisy-btn", @class]}>Theme</summary>
        <ul class={["bg-base-300 rounded", @props[:uclass]]}>
          <li :for={{value, label} <- [{"default", "Default"}, {"dark", "Dark"}, {"light", "Light"}]}>
            <input type="radio" name="payload" value={value} aria-label={label}
              class={["daisy-btn daisy-btn-ghost theme-controller w-full", @props[:rclass]]}>
          </li>
        </ul>
      </details>
    </form>
    """
  end
end
