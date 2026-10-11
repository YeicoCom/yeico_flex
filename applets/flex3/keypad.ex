defmodule Flex.Keypad do
  use Terminal.Live

  def render(assigns) do
    ~H"""
      <div class="grid grid-cols-7 gap-4 pt-2">
        <.fui fun={&button/1} key="0" {assigns}>0</.fui>
        <.fui fun={&button/1} key="1" {assigns}>1</.fui>
        <.fui fun={&button/1} key="2" {assigns}>2</.fui>
        <.fui fun={&button/1} key="3" {assigns}>3</.fui>
        <.fui fun={&button/1} key="4" {assigns}>4</.fui>
        <.fui fun={&button/1} key="Backspace" {assigns} class="flex justify-between col-span-2">
          <div>Back</div><div class="hero-backspace"/></.fui>
        <.fui fun={&button/1} key="5" {assigns}>5</.fui>
        <.fui fun={&button/1} key="6" {assigns}>6</.fui>
        <.fui fun={&button/1} key="7" {assigns}>7</.fui>
        <.fui fun={&button/1} key="8" {assigns}>8</.fui>
        <.fui fun={&button/1} key="9" {assigns}>9</.fui>
        <.fui fun={&button/1} key="Enter" {assigns} class="flex justify-between col-span-2">
          <div>Enter</div><div class="hero-arrow-turn-down-left"/></.fui>
      </div>
    """
  end

  defp button(assigns) do
    assigns = Map.put_new(assigns, :class, nil)

    ~H"""
    <button id={"kpb_#{@key}"} type="button" tabindex="-1" class={["px-6 py-4 border border-neutral-400 rounded outline-none", @class]}
      phx-hook="Keypad" data-key={@key} data-form-id={@form_id} data-input-id={@input_id}>
      {render_slot(@inner_block)}
    </button>
    """
  end
end
