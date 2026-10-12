use Terminal.Live

# test: logging from events
# test: accurate stacktraces
# test: logs and stacktraces from render
# test: shared state and events
# test: mount and render events
# test: point and timer events
# test: click events
# test: global state
#
# http://localhost:4080/screen1
# Adb.list
# Api.putcast!("screen1:point1", 1)
# Api.putcast!("screen1:point1", 0)
# Api.putcast!("screen1:point1", nil)
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/screen1")
|> Flex.LiveScreen.set(title: "Screen1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(shared: %{count: 5})
|> Flex.LiveScreen.add(
  {0, 0},
  [
    {:warn1, {:point, "screen1:warn1"}},
    {:throw1, {:point, "screen1:throw1"}}
  ],
  fn
    # log confirmed to work in render callback
    # Api.putcast!("screen1:warn1", :render)
    # Api.putcast!("screen1:warn1", :mount)
    # Api.putcast!("screen1:warn1", nil)
    # Api.putcast!("screen1:throw1", :render)
    # Api.putcast!("screen1:throw1", :mount)
    # Api.putcast!("screen1:throw1", nil)
    assigns = %{warn: warn, event: :render, inputs: %{warn1: warn1, throw1: throw1}} ->
      if warn1 == :render, do: warn.(event: :render)
      if throw1 == :render, do: throw(event: :render)

      ~H"""
      """

    %{state: state, warn: warn, event: event, inputs: %{warn1: warn1, throw1: throw1}} ->
      if warn1 == event, do: warn.(event: event)
      if throw1 == event, do: throw(event: event)
      state
  end
)
|> Flex.LiveScreen.add(
  {40, 20},
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="text-[24px] w-[300px] p-2 bg-neutral-300 rounded cursor-pointer"
        phx-click="click" phx-value-index={@index}>
        Click me count: {@shared.count}
      </div>
      """

    ctx = %{state: state, event: {:event, "click", _params}} ->
      # first one should be ignored when changed? false
      ctx.share.(:count, ctx.shared.count)
      ctx.share.(:count, ctx.shared.count + 1)
      state

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.add(
  {40, 80},
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="text-[24px] w-[300px] p-2 bg-neutral-300 rounded">
        Shared click count: {@shared[:count]}
      </div>
      """

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.add(
  {440, 20},
  [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "screen1:point1"}}
  ],
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="text-[24px] w-[12em] p-2 bg-neutral-300 rounded">
        <div>Calculated: {@state.value}</div>
      </div>
      """

    ctx = %{state: state, event: :mount} ->
      calc = fn %{inputs: inputs} -> (inputs.point1 || inputs.const1) * inputs.timer1 end
      Map.merge(state, %{calc: calc, value: calc.(ctx)})

    ctx = %{state: state} ->
      Map.merge(state, %{value: state.calc.(ctx)})
  end
)
|> Flex.LiveScreen.run()

:ok
