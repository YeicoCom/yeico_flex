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
|> Flex.LiveScreen.add(:class, "ll:label", "select-none text-blue-600 text-[24px]")
|> Flex.LiveScreen.add(:class, "ll:input", "bg-blue-600 text-blue-400 text-[24px]")
|> Flex.LiveScreen.add(:class, "ll:input", "text-center rounded-lg ring-0 focus:ring-0")
|> Flex.LiveScreen.add(
  {300, 200},
  fn
    %{state: assigns, event: :render} ->
      ~H"""
      <div class="text-[24px] text-center text-red-500 w-[200px] p-2 bg-gray-800 rounded-lg">
        Welcome
      </div>
      """

    %{state: state, index: index, event: event, trace: trace, global: %{connected?: connected?}} ->
      trace.(index: index, event: event, connected?: connected?)
      state
  end
)
|> Flex.LiveScreen.run()

:ok
