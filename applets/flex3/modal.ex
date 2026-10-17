defmodule Flex.Modal do
  use Terminal.Live

  def render(assigns) do
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :index, nil)
    assigns = Map.put_new(assigns, :close, "modal:close")
    assigns = Map.put_new(assigns, :away, "modal:close")

    ~H"""
    <div class="fixed top-0 left-0 z-9999 w-screen h-screen bg-stone-500/90">
      <div class="flex justify-center items-center h-screen select-none text-base">
        <div class="p-8 rounded-md bg-neutral-300 text-neutral-500" phx-click-away={@away} phx-value-index={@index}>
          <div class="pb-2 gap-20 flex justify-between items-center">
            <div class="font-semibold">{@title}</div>
            <button type="button" title="Close" phx-click={@close} phx-value-index={@index} tabindex="-1"
              class="hover:bg-neutral-500 hover:text-neutral-200 rounded-lg w-8 h-8 inline-flex justify-center items-center">
              <span class="hero-x-mark-solid" />
            </button>
          </div>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end
end
