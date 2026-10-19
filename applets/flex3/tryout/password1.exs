use Terminal.Live

keypad = fn localhost? -> Terminal.dev?() || (localhost? && Terminal.device?()) end

# test: password logic
# http://localhost:4080/password1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/password1")
|> Flex.LiveScreen.set(title: "Password1 1234")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(keypad: keypad)
|> Flex.LiveScreen.set(pass: fn -> "1234" end)
|> Flex.LiveScreen.add(
  {0, 0},
  fn
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
