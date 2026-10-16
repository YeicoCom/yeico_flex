use Terminal.Live

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/form2")
|> Flex.LiveScreen.set(title: "Form2")
|> Flex.LiveScreen.set(width: 400)
|> Flex.LiveScreen.set(height: 1000)
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
