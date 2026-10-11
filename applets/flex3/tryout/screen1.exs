use Terminal.Live

# test: stacktrace with filename and line number
# test: viewport styling customization by @class (dropped in favor a sensible default + themes)
# test: viewport styling customization by @style (dropped in favor a sensible default + themes)
# test: logs from events including render
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
# generate an arithmetic error
# Api.putcast!("screen1:point1", true)
# generate an render throw
# Api.putcast!("screen1:render1", true)
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/screen1")
|> Flex.LiveScreen.set(title: "Screen1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(shared: %{count: 5})
|> Flex.LiveScreen.add(
  {0, 0},
  [
    {:render1, {:point, "screen1:render1"}}
  ],
  fn
    # log confirmed to work in render callback
    # Api.putcast!("screen1:render1", true)
    # Api.putcast!("screen1:render1", false)
    assigns = %{warn: warn, event: :render, inputs: %{render1: render1}} ->
      if render1, do: warn.(render1: render1)
      if render1, do: throw(render1: render1)

      ~H"""
      """

    %{state: state, warn: warn, event: event} ->
      warn.(event: event)
      # throw(event: event)
      state
  end
)
|> Flex.LiveScreen.add(
  {40, 20},
  [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "screen1:point1"}}
  ],
  fn
    # :mount, :render, {:timer, :timer1}, {:point, :point1}, {:event, "click", _params}
    # log confirmed to work in render callback
    %{state: assigns, event: :render} ->
      ~H"""
      <div class="text-[24px] w-[12em] p-2 bg-neutral-300 rounded">
        <div>Calculated: {@value}</div>
      </div>
      """

    %{state: state, event: :mount, inputs: inputs} ->
      calc = fn %{const1: const1, timer1: timer1, point1: point1} ->
        (point1 || const1) * timer1
      end

      Map.merge(state, %{calc: calc, value: calc.(inputs)})

    %{state: state = %{calc: calc}, inputs: inputs} ->
      Map.merge(state, %{value: calc.(inputs)})
  end
)
|> Flex.LiveScreen.add(
  {440, 20},
  fn
    %{state: state, shared: shared, event: :render} ->
      assigns = Map.put(state, :shared, shared)

      ~H"""
      <div class="text-[24px] w-[300px] p-2 bg-neutral-300 rounded cursor-pointer"
        phx-click="click" phx-value-index={@index}>
        Click me count: {@shared[:count]}
      </div>
      """

    %{state: state, shared: %{count: count}, event: {:event, "click", _params}, put: put} ->
      # first one should be ignored when changed? false
      put.(:count, count)
      put.(:count, count + 1)
      state

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.add(
  {440, 80},
  fn
    %{state: state, shared: shared, event: :render} ->
      assigns = Map.put(state, :shared, shared)

      ~H"""
      <div class="text-[24px] w-[300px] p-2 bg-neutral-300 rounded">
        Shared click count: {@shared[:count]}
      </div>
      """

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
