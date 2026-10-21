use Terminal.Live

Flex.ReactiveLogic.new()
|> Flex.ReactiveLogic.set(id: "logic1")
|> Flex.ReactiveLogic.add(Flex.ReactorWrapper,
  inputs: [
    {:timer1, {:timer, 500}}
  ],
  handler: fn %{state: state, inputs: %{timer1: timer1}} ->
    Api.putcast!("logic1:timer1", timer1)
    state
  end
)
|> Flex.ReactiveLogic.run(rdms: 1000)

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "Widgets")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add({10, 10}, Flex.DaisyToggleIndicator,
  source: {:timer, 500},
  class: "daisy-toggle-accent",
  calc: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({60, 10}, Flex.DaisyToggleIndicator,
  source: {:timer, 500},
  class: "daisy-toggle-accent",
  calc: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({10, 40}, Flex.DaisyToggleIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-toggle-accent",
  calc: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({60, 40}, Flex.DaisyToggleIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-toggle-accent",
  calc: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({10, 70}, Flex.DaisyToggleControl,
  sink: {:shared, :toggle},
  class: "daisy-toggle-accent",
  calc: fn v -> v == "on" end
)
|> Flex.LiveScreen.add({60, 70}, Flex.DaisyToggleIndicator,
  source: {:shared, :toggle},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({10, 100}, Flex.DaisyToggleControl,
  sink: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent",
  calc: fn v -> v == "on" end
)
|> Flex.LiveScreen.add({60, 100}, Flex.DaisyToggleIndicator,
  source: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({200, 10}, Flex.DaisyRangeIndicator,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> rem(v, 10) end
)
|> Flex.LiveScreen.add({300, 10}, Flex.DaisyRangeIndicator,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> rem(v, 10) end
)
|> Flex.LiveScreen.add({200, 40}, Flex.DaisyRangeIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> rem(v, 10) end
)
|> Flex.LiveScreen.add({300, 40}, Flex.DaisyRangeIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> rem(v, 10) end
)
|> Flex.LiveScreen.add({200, 70}, Flex.DaisyRangeControl,
  sink: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> v || "0" end
)
|> Flex.LiveScreen.add({300, 70}, Flex.DaisyRangeIndicator,
  source: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1}
)
|> Flex.LiveScreen.add({200, 100}, Flex.DaisyRangeControl,
  sink: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1},
  calc: fn v -> Flex.Parse.float!(v || "0") end
)
|> Flex.LiveScreen.add({300, 100}, Flex.DaisyRangeIndicator,
  source: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 9, step: 1}
)
|> Flex.LiveScreen.run()

:ok
