use Terminal.Live

# test: password logic
# test: login styling customization
# http://localhost:4080/password1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/password1")
|> Flex.LiveScreen.set(title: "Password1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(pass: fn -> "flex" end)
|> Flex.LiveScreen.add(
  {0, 0},
  fn
    %{state: assigns, event: :render} ->
      ~H"""
      <div class="p-2">Welcome</div>
      """

    %{state: state, index: index, event: event, trace: trace, global: %{connected?: connected?}} ->
      trace.(index: index, event: event, connected?: connected?)
      state
  end
)
|> Flex.LiveScreen.run()

:ok
