use Terminal

# Adb.list
# Api.putcast!("logic1:point1", 1)
# Api.putcast!("logic1:point1", 0)
# Api.putcast!("logic1:point1", nil)
# generate an arithmetic error
# Api.putcast!("logic1:point1", true)
Flex.ReactiveLogic.new()
|> Flex.ReactiveLogic.add(Flex.ReactorWrapper,
  inputs: [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "logic1:point1"}}
  ],
  handler: fn %{state: state, inputs: inputs} ->
    %{const1: const1, timer1: timer1, point1: point1} = inputs
    value = (point1 || const1) * timer1
    Api.putcast!("logic1:calc1", value)
    state
  end
)
|> Flex.ReactiveLogic.run(rdms: 1000)

:ok
