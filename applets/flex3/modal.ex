defmodule Flex.Modal do
  use Terminal.Live

  def render(assigns) do
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :index, nil)
    assigns = Map.put_new(assigns, :theme, nil)
    assigns = Map.put_new(assigns, :close, "modal:close")
    assigns = Map.put_new(assigns, :away, "modal:close")

    ~H"""
    <dialog data-theme={@theme} class="daisy-modal w-screen h-screen" open>
      <div class="daisy-modal-box text-base-content w-fit" phx-click-away={@away} phx-value-index={@index}>
        <div :if={@title} class="pb-2 gap-2 flex justify-between items-center">
          <div class="font-semibold">{@title}</div>
          <button type="button" title="Close" phx-click={@close} phx-value-index={@index}
            tabindex="-1" class="daisy-btn daisy-btn-ghost p-0 min-h-min h-fit">
            <span class="hero-x-mark-solid" />
          </button>
        </div>
        {render_slot(@inner_block)}
      </div>
    </dialog>
    """
  end
end
