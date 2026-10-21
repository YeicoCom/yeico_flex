use Terminal.Live

keypad = fn localhost? -> Terminal.dev?() || (localhost? && Terminal.device?()) end

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "Password 1234")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(keypad: keypad)
|> Flex.LiveScreen.set(pass: fn -> "1234" end)
|> Flex.LiveScreen.add(
  {0, 0},
  Flex.ReactorWrapper,
  handler: fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="p-2">Welcome</div>
      """

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
