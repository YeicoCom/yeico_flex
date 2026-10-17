use Terminal.Live

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/form1")
|> Flex.LiveScreen.set(title: "Form1")
|> Flex.LiveScreen.set(width: 600)
|> Flex.LiveScreen.set(height: 800)
|> Flex.LiveScreen.add(
  {0, 0},
  fn
    assigns = %{event: :render} ->
      render.(assigns)

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
