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
|> Flex.LiveScreen.add({110, 10}, Flex.DaisyToggleIndicator,
  source: {:timer, 500},
  visible: {:timer, 500},
  visible?: fn value -> rem(value, 3) == 0 end,
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
|> Flex.LiveScreen.add({110, 40}, Flex.DaisyToggleIndicator,
  source: {:point, "logic1:timer1"},
  visible: {:point, "logic1:timer1"},
  visible?: fn value -> rem(value, 3) == 0 end,
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
|> Flex.LiveScreen.add({110, 70}, Flex.DaisyToggleIndicator,
  source: {:shared, :toggle},
  visible: {:shared, :toggle},
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
|> Flex.LiveScreen.add({110, 100}, Flex.DaisyToggleIndicator,
  source: {:point, "screen1:toggle1"},
  visible: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({200, 10}, Flex.DaisyRangeIndicator,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({300, 10}, Flex.DaisyRangeIndicator,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({200, 40}, Flex.DaisyRangeIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({300, 40}, Flex.DaisyRangeIndicator,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({200, 70}, Flex.DaisyRangeControl,
  sink: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  calc: fn v -> Flex.Parse.float!(v || "0") end
)
|> Flex.LiveScreen.add({300, 70}, Flex.DaisyRangeIndicator,
  source: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5}
)
|> Flex.LiveScreen.add({200, 100}, Flex.DaisyRangeControl,
  sink: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  calc: fn v -> Flex.Parse.float!(v || "0") end
)
|> Flex.LiveScreen.add({300, 100}, Flex.DaisyRangeIndicator,
  source: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1}
)
|> Flex.LiveScreen.add({450, 10}, Flex.MovingAnalogIndicator,
  value: {:timer, 500},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({500, 10}, Flex.MovingAnalogIndicator,
  value: {:point, "logic1:timer1"},
  calc: fn v -> rem(v, 11) end
)
|> Flex.LiveScreen.add({550, 10}, Flex.MovingAnalogIndicator, value: {:shared, :range})
|> Flex.LiveScreen.add({600, 10}, Flex.MovingAnalogIndicator, value: {:point, "screen1:range1"})
|> Flex.LiveScreen.run()

:ok
