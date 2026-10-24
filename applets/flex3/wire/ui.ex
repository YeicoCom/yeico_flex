defmodule Wire.UI do
  use Terminal.Live

  # data-KEY for hooks
  # phx-value-KEY for events
  def phxattr(assigns) do
    Map.put_new(
      assigns,
      :phxattr,
      for {k, v} <- assigns, reduce: %{} do
        acc ->
          case List.first(String.split("#{k}", "-")) in ["phx", "data"] do
            true -> Map.put(acc, k, v)
            _ -> acc
          end
      end
    )
  end

  # modal assumed to be laid outside frame
  def modal(assigns) do
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :class, nil)

    ~H"""
    <.fui fun={&Flex.Modal.render/1} title={@title}>
      <div class={["pt-2", @class]}>
      {render_slot(@inner_block)}
      </div>
    </.fui>
    """
  end

  def select(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :name, nil)
    assigns = Map.put_new(assigns, :size, nil)
    assigns = Map.put_new(assigns, :value, nil)
    assigns = Map.put_new(assigns, :values, [])
    assigns = Map.put_new(assigns, :values2, [])
    assigns = Map.put_new(assigns, :required, nil)
    assigns = Map.put_new(assigns, :disabled, nil)

    ~H"""
    <select
    name={@name}
    size={@size}
    required={@required}
    disabled={@disabled}
    {@phxattr}
    class={["daisy-select daisy-select-bordered daisy-select-sm", @class]}>
    <option :for={value <- @values} value={value}
      selected={value==@value} title={value}
      class="p-2 checked:bg-lime-500 checked:text-white">{value}</option>
    <option :for={{value, label} <- @values2} value={value}
      selected={value==@value} title={label}
      class="p-2 checked:bg-lime-500 checked:text-white">{label}</option>
    </select>
    """
  end

  def input(assigns) do
    assigns = phxattr(assigns)
    # wont honor focus ring color if type nil
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :type, "text")
    assigns = Map.put_new(assigns, :name, nil)
    assigns = Map.put_new(assigns, :value, nil)
    assigns = Map.put_new(assigns, :disabled, nil)
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :required, nil)
    assigns = Map.put_new(assigns, :size, nil)
    # number type
    assigns = Map.put_new(assigns, :step, nil)
    assigns = Map.put_new(assigns, :min, nil)
    assigns = Map.put_new(assigns, :max, nil)
    # text type
    assigns = Map.put_new(assigns, :pattern, nil)

    ~H"""
    <input
    id={@id}
    type={@type}
    name={@name}
    value={@value}
    disabled={@disabled}
    required={@required}
    pattern={@pattern}
    title={@title}
    size={@size}
    step={@step}
    min={@min}
    max={@max}
    {@phxattr}
    class={["daisy-input daisy-input-bordered daisy-input-sm", @class]}/>
    """
  end

  def button(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :type, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :disabled, nil)

    ~H"""
    <button
    type={@type}
    disabled={@disabled}
    {@phxattr}
    class={["daisy-btn daisy-btn-outline daisy-btn-sm", @class]}>
    {render_slot(@inner_block)}
    </button>
    """
  end

  def link(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :disabled, nil)
    assigns = Map.put_new(assigns, :type, "normal")

    hover =
      case assigns.type do
        "danger" -> "hover:text-warning"
        _ -> ""
      end

    assigns = Map.put_new(assigns, :hover, hover)

    ~H"""
    <div
    title={@title}
    disabled={@disabled}
    {@phxattr}
    class={["daisy-link daisy-link-hover daisy-link-sm w-fit", @hover,  @class]}>
    {render_slot(@inner_block)}
    </div>
    """
  end
end
