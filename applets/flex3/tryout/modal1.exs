use Terminal.Live

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "Modal1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add(
  {0, 0},
  Flex.ReactorWrapper,
  inputs: [
    {:width, {:shared, :width}},
    {:height, {:shared, :height}}
  ],
  handler: fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="flex flex-col items-center justify-center" style={"width:#{@inputs.width}px;height:#{@inputs.height}px;"}>
        <button phx-click="modal:open" phx-value-index={@index} class="daisy-btn">
          Open Modal 1
        </button>
      </div>
      """

    # pass phx-value-index={@index} to get the close event callback
    %{state: state, modal: modal, event: {:event, "modal:open", _}} ->
      handler = fn assigns ->
        ~H"""
        <div class="flex flex-col items-center justify-center">
          <button phx-click="modal:close" class="daisy-btn">
            Close Modal 1
          </button>
        </div>
        """
      end

      modal.(%{handler: handler, props: %{title: "Modal Title"}})
      state

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
