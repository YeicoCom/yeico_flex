defmodule Flex.Keypad do
  use Terminal.Live

  def render(assigns) do
    ~H"""
      <div class="grid grid-cols-7 gap-4 pt-2">
        <.fui fun={&button/1} key="0" hook="Keypad" input={@input}>0</.fui>
        <.fui fun={&button/1} key="1" hook="Keypad" input={@input}>1</.fui>
        <.fui fun={&button/1} key="2" hook="Keypad" input={@input}>2</.fui>
        <.fui fun={&button/1} key="3" hook="Keypad" input={@input}>3</.fui>
        <.fui fun={&button/1} key="4" hook="Keypad" input={@input}>4</.fui>
        <.fui fun={&button/1} key="Backspace" hook="Keypad" input={@input} class="flex justify-between col-span-2">
          <div>Back</div><div class="hero-backspace"/></.fui>
        <.fui fun={&button/1} key="5" hook="Keypad" input={@input}>5</.fui>
        <.fui fun={&button/1} key="6" hook="Keypad" input={@input}>6</.fui>
        <.fui fun={&button/1} key="7" hook="Keypad" input={@input}>7</.fui>
        <.fui fun={&button/1} key="8" hook="Keypad" input={@input}>8</.fui>
        <.fui fun={&button/1} key="9" hook="Keypad" input={@input}>9</.fui>
        <.fui fun={&button/1} key="Enter" type="submit" class="flex justify-between col-span-2">
          <div>Enter</div><div class="hero-arrow-turn-down-left"/></.fui>
      </div>
    """
  end

  # key required for button id as well
  defp button(assigns) do
    assigns = Map.put_new(assigns, :hook, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :input, nil)
    assigns = Map.put_new(assigns, :type, "button")

    ~H"""
    <button id={"kpb_#{@key}"} type={@type} tabindex="-1" class={["px-6 py-4 border border-neutral-400 rounded outline-none", @class]}
      phx-hook={@hook} data-key={@key} data-input={@input}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
