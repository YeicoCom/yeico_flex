use Terminal.Live

Flex.ReactiveLogic.new()
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
|> Flex.LiveScreen.add({10, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:timer, 500},
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({60, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:timer, 500},
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({110, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:timer, 500},
  visible: {:timer, 500},
  visible?: fn value -> rem(value, 3) == 0 end,
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({10, 40}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:point, "logic1:timer1"},
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({60, 40}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:point, "logic1:timer1"},
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({110, 40}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:point, "logic1:timer1"},
  visible: {:point, "logic1:timer1"},
  visible?: fn value -> rem(value, 3) == 0 end,
  class: "daisy-toggle-accent",
  icast: fn value -> rem(value, 2) == 0 end
)
|> Flex.LiveScreen.add({10, 70}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  sink: {:shared, :toggle},
  class: "daisy-toggle-accent",
  ocast: fn v -> v == "on" end
)
|> Flex.LiveScreen.add({60, 70}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:shared, :toggle},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({110, 70}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:shared, :toggle},
  visible: {:shared, :toggle},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({10, 100}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  sink: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent",
  ocast: fn v -> v == "on" end
)
|> Flex.LiveScreen.add({60, 100}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({110, 100}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.toggle/1,
  source: {:point, "screen1:toggle1"},
  visible: {:point, "screen1:toggle1"},
  class: "daisy-toggle-accent"
)
|> Flex.LiveScreen.add({200, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  icast: fn v -> rem(v || 0, 11) end
)
|> Flex.LiveScreen.add({300, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:timer, 500},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  icast: fn v -> rem(v || 0, 11) end
)
|> Flex.LiveScreen.add({200, 40}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1},
  icast: fn v -> rem(v || 0, 11) end
)
|> Flex.LiveScreen.add({300, 40}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:point, "logic1:timer1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  icast: fn v -> rem(v || 0, 11) end
)
|> Flex.LiveScreen.add({200, 70}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  sink: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  ocast: fn v -> Flex.Parse.float!(v || "0") end
)
|> Flex.LiveScreen.add({300, 70}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:shared, :range},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5}
)
|> Flex.LiveScreen.add({200, 100}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  sink: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 0.5},
  ocast: fn v -> Flex.Parse.float!(v || "0") end
)
|> Flex.LiveScreen.add({300, 100}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.range/1,
  source: {:point, "screen1:range1"},
  class: "daisy-range-accent w-24",
  props: %{min: 0, max: 10, step: 1}
)
|> Flex.LiveScreen.add({450, 10}, Flex.MovingAnalogIndicator,
  value: {:timer, 500},
  cast: fn v -> rem(v || 0, 11) end
)
|> Flex.LiveScreen.add({500, 10}, Flex.MovingAnalogIndicator,
  value: {:point, "logic1:timer1"},
  cast: fn v -> rem(v || 0, 11) end,
  border?: true
)
|> Flex.LiveScreen.add({10, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.button/1,
  ocast: fn v -> String.to_integer(v) end,
  sink: {:point, "screen1:button1"},
  class: "daisy-btn-outline",
  props: %{text: "Select 1"},
  oinitial: "1"
)
|> Flex.LiveScreen.add({100, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.button/1,
  ocast: fn v -> String.to_integer(v) end,
  sink: {:point, "screen1:button1"},
  class: "daisy-btn-outline",
  props: %{text: "Select 2"},
  oinitial: "2"
)
|> Flex.LiveScreen.add({10, 280}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.select/1,
  ocast: fn v -> String.to_integer(v) end,
  sink: {:point, "screen1:button1"},
  class: "daisy-select-bordered h-auto py-1",
  props: %{size: 2, oclass: "p-1", options: [{1, "Select 1"}, {2, "Select 2"}]},
  oinitial: "0"
)
|> Flex.LiveScreen.add({200, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.label/1,
  source: {:point, "screen1:button1"},
  icast: fn v -> "Button #{v}" end,
  class: "text-success"
)
|> Flex.LiveScreen.add({200, 230}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.label/1,
  source: {:point, "logic1:timer1"},
  icast: fn v -> "Timer1 #{v}" end,
  class: "text-success"
)
|> Flex.LiveScreen.add({700, 10}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.theme/1,
  props: %{rclass: "daisy-btn-sm"},
  class: "daisy-btn-outline daisy-btn-sm"
)
|> Flex.LiveScreen.add({300, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:timer, 500},
  icast: fn v -> rem(v || 0, 11) end,
  class: "w-24",
  props: %{max: 10}
)
|> Flex.LiveScreen.add({300, 220}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:point, "logic1:timer1"},
  icast: fn v -> rem(v || 0, 11) end,
  class: "w-24",
  props: %{max: 10}
)
|> Flex.LiveScreen.add({300, 240}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:shared, :range},
  class: "w-24",
  props: %{max: 10}
)
|> Flex.LiveScreen.add({300, 260}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:point, "screen1:range1"},
  class: "w-24",
  props: %{max: 10}
)
|> Flex.LiveScreen.add({420, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:timer, 500},
  icast: fn v -> rem(v || 0, 101) end,
  class: "text-xs text-success",
  props: %{type: :radial, size: "6em"}
)
|> Flex.LiveScreen.add({500, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:point, "logic1:timer1"},
  icast: fn v -> rem(v || 0, 101) end,
  class: "text-xs text-success",
  props: %{type: :radial, size: "6em", thickness: "1px"}
)
|> Flex.LiveScreen.add({580, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:shared, :range},
  icast: fn v -> 10 * (v || 0) end,
  class: "text-xs text-success",
  props: %{type: :radial, size: "6em"}
)
|> Flex.LiveScreen.add({660, 200}, Flex.ValueWidget,
  render: &Flex.DaisyWidgets.progress/1,
  source: {:point, "screen1:range1"},
  icast: fn v -> 10 * (v || 0) end,
  class: "text-xs text-success",
  props: %{type: :radial, size: "6em"}
)
|> Flex.LiveScreen.add({550, 10}, Flex.MovingAnalogIndicator,
  value: {:shared, :range},
  rounded?: true
)
|> Flex.LiveScreen.add({600, 10}, Flex.MovingAnalogIndicator, value: {:point, "screen1:range1"})
|> Flex.LiveScreen.add({150, 300}, Flex.MovingAnalogIndicator,
  value: {:point, "screen1:range1"},
  error: {0.0, 8.0}
)
|> Flex.LiveScreen.add({200, 300}, Flex.MovingAnalogIndicator,
  value: {:point, "screen1:range1"},
  warn: {0.0, 6.0}
)
|> Flex.LiveScreen.add({250, 300}, Flex.MovingAnalogIndicator,
  value: {:point, "screen1:range1"},
  error: {1.0, 10.0}
)
|> Flex.LiveScreen.add({300, 300}, Flex.MovingAnalogIndicator,
  value: {:point, "screen1:range1"},
  warn: {2.0, 10.0}
)
|> Flex.LiveScreen.add({400, 300}, Flex.SparkWidget,
  props: %{
    "data-dot-radius" => "3",
    "data-min-value" => "0",
    "data-max-value" => "10"
  },
  source: {:point, "logic1:timer1"},
  icast: fn v -> rem(v || 0, 11) end,
  class: "w-64 h-36",
  maxlen: 50
)
|> Flex.LiveScreen.run()

:ok
