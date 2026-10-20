use Terminal.Live

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "Widgets")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add({10, 10}, Flex.DaisyToggleInput,
  source: {:timer, 1000},
  class: "daisy-toggle-accent",
  calc: fn _ctx, value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.run()

:ok
