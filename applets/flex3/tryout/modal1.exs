use Terminal.Live

# http://localhost:4080/hmi1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/modal1")
|> Flex.LiveScreen.set(title: "Modal1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add(
  {0, 0},
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="flex flex-col items-center justify-center" style={"width:#{@global.width}px;height:#{@global.height}px;"}>
        <button phx-click="modal:open" phx-value-index={@index} class="border border-black outline-none rounded p-4 cursor-pointer">
          Open Modal
        </button>
      </div>
      """

    %{state: state, modal: modal, event: {:event, "modal:open", _}} ->
      fun = fn assigns ->
        ~H"""
        <div class="w-[400px] flex flex-col items-center justify-center"}>
          <button phx-click="modal:close" class="border border-black rounded p-4 cursor-pointer">
            Close Modal
          </button>
        </div>
        """
      end

      modal.(%{fun: fun, props: %{title: "Modal Title"}})
      state

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
