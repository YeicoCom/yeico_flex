use Terminal.Live

Adb.reset()

# should not be really needed since serial export cleans on setup
System.shell("sudo killall socat", stderr_to_stdout: true)

Api.path()
|> Path.join("flex3/**/test/*.exs")
|> Path.wildcard()
|> Enum.map(&String.trim_leading(&1, Api.path()))
|> Enum.map(&String.trim_leading(&1, "/"))
|> Enum.each(&Api.evalf/1)

Flex.EchoServer.new()
|> Flex.EchoServer.set(ip: "127.0.0.1")
|> Flex.EchoServer.set(port: 4021)
|> Flex.EchoServer.run()

Flex.ModbusSlave.new()
|> Flex.ModbusSlave.set(key: "modbus:slave:tcp")
|> Flex.ModbusSlave.set(proto: "TCP")
|> Flex.ModbusSlave.set(ip: "127.0.0.1")
|> Flex.ModbusSlave.set(port: 4031)
|> Flex.ModbusSlave.run()

Flex.ModbusSlave.new()
|> Flex.ModbusSlave.set(key: "modbus:slave:rtu")
|> Flex.ModbusSlave.set(proto: "RTU")
|> Flex.ModbusSlave.set(ip: "127.0.0.1")
|> Flex.ModbusSlave.set(port: 4032)
|> Flex.ModbusSlave.run()

Flex.ShellCommand.new()
|> Flex.ShellCommand.set(id: "socat_pair")
|> Flex.ShellCommand.set(
  run: """
  # do not use -9 or sudo wont kill child socat process
  [ -f $FLEX_RUN/socat_pair.pid ] && sudo kill $(cat $FLEX_RUN/socat_pair.pid)
  sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B &
  echo $! > $FLEX_RUN/socat_pair.pid
  # System.shell waits for background processes with trailing &
  """
)
|> Flex.ShellCommand.set(
  kill: """
  # do not use -9 or sudo wont kill child socat process
  [ -f $FLEX_RUN/socat_pair.pid ] && sudo kill $(cat $FLEX_RUN/socat_pair.pid)
  """
)
|> Flex.ShellCommand.run(rdms: 1000)

Flex.SerialExport.new()
|> Flex.SerialExport.set(tty: "/tmp/tty.socat.A")
|> Flex.SerialExport.set(port: 4041)
|> Flex.SerialExport.run(rdms: 1000)

# test with:
# Adb.list
# Flex.Points.put_value("sink:bit:D0", 1)
# Flex.Points.put_value("sink:bit:D0", 0)
# Flex.Points.put_value("sink:uint16:R0", 0)
# Flex.Points.put_value("sink:uint16:R0", 2)
Flex.ModbusDevice.new()
|> Flex.ModbusDevice.set(name: "device1")
|> Flex.ModbusDevice.set(ip: "127.0.0.1")
|> Flex.ModbusDevice.set(port: 4031)
|> Flex.ModbusDevice.set(proto: "TCP")
|> Flex.ModbusDevice.set(delay: 20)
|> Flex.ModbusDevice.add(%{type: "WDO", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"})
|> Flex.ModbusDevice.add(%{type: "RDI", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"})
|> Flex.ModbusDevice.add(%{type: "WRO", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"})
|> Flex.ModbusDevice.add(%{type: "RRI", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"})
|> Flex.ModbusDevice.run(rdms: 1000)

# Adb.list
# Api.putcast!("logic1:point1", 1)
# Api.putcast!("logic1:point1", 0)
# Api.putcast!("logic1:point1", nil)
# generate an arithmetic error
# Api.putcast!("logic1:point1", true)
Flex.ReactiveLogic.new()
|> Flex.ReactiveLogic.set(id: "logic1")
|> Flex.ReactiveLogic.add(
  [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "logic1:point1"}}
  ],
  fn ctx = %{state: state, inputs: inputs, event: event} ->
    # :mount, {:timer, :timer1}, {:point, :point1}
    if event == :mount, do: ctx.trace.("mount")
    %{const1: const1, timer1: timer1, point1: point1} = inputs
    value = (point1 || const1) * timer1
    Api.putcast!("logic1:calc1", value)
    state
  end
)
|> Flex.ReactiveLogic.run(rdms: 1000)

# test: stacktrace with filename and line number
# test: viewport styling customization by @class
# test: viewport styling customization by @style
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
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/screen1")
|> Flex.LiveScreen.set(title: "Screen1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(shared: %{count: 5})
|> Flex.LiveScreen.add(:class, "ls:main", "select-none bg-stone-700")
|> Flex.LiveScreen.add(:class, "ls:panel", "bg-[#e6e6e6]")
|> Flex.LiveScreen.set(
  style: """
  #ls_main:hover {
    background-color: #e6e6e6;
  }
  #ls_panel:hover {
    background-color: #44403C;
  }
  """
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
      <div class="text-[24px] w-[12em] p-2 bg-black rounded">
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
      <div class="text-[24px] w-[300px] p-2 bg-black rounded cursor-pointer"
        phx-click="click" phx-value-index={@index}>
        Click me count: {@shared[:count]}
      </div>
      """

    %{state: state, shared: %{count: count}, event: {:event, "click", _params}, put: put} ->
      # first one should be ignored when changed? false
      put.(:count, count)
      put.(:count, count + 1)
      state

    %{state: state, index: index, event: event, trace: trace, global: %{connected?: connected?}} ->
      trace.(index: index, event: event, connected?: connected?)
      state
  end
)
|> Flex.LiveScreen.add(
  {440, 80},
  fn
    %{state: state, shared: shared, event: :render} ->
      assigns = Map.put(state, :shared, shared)

      ~H"""
      <div class="text-[24px] w-[300px] p-2 bg-black rounded">
        Shared click count: {@shared[:count]}
      </div>
      """

    %{state: state, index: index, event: event, trace: trace, global: %{connected?: connected?}} ->
      trace.(index: index, event: event, connected?: connected?)
      state
  end
)
|> Flex.LiveScreen.run()

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

# http://localhost:4080/hmi1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/hmi1")
|> Flex.LiveScreen.set(title: "HMI1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add(:class, "ls:main", "bg-stone-700 select-none")
|> Flex.LiveScreen.add(:class, "ls:panel", "bg-[#e6e6e6]")
|> Flex.LiveScreen.set(shared: %{menu: 1})
|> Flex.LiveScreen.add(
  {0, 0},
  [{:time, {:timer, 1000}}],
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="bg-[#cccccc] w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center gap-[4px]">
          <div>Screen Title</div>
          <div class="grow"/>
          <div class="hero-wifi"/>
          <div class="hero-arrows-up-down"/>
        </div>
      </div>
      <div class="h-[400px]"/>
      <div class="bg-[#cccccc] w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center">
          <img src="/applets/logo.svg" class="h-[28px] pe-[12px] grayscale">
          <div :for={menu <- 1..3} class={["px-[12px] py-[1px] cursor-pointer rounded", @shared.menu==menu && "bg-[#aaaaaa] text-white"]}
            phx-click="click:menu" phx-value-index={@index} phx-value-menu={menu}>{"Menu#{menu}"}</div>
          <div class="grow"/>
          <div>{@state.time}</div>
        </div>
      </div>
      """

    %{state: state, event: {:event, "click:menu", %{"menu" => menu}}, put: put} ->
      put.(:menu, String.to_integer(menu))
      state

    %{state: state, global: %{tzoffset: tzoffset}} ->
      time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.shift(hour: tzoffset || 0)
        |> Calendar.strftime("%H:%M:%S")

      Map.put(state, :time, time)
  end
)
|> (fn config ->
      for {v, i} <- [5, 1.5, 7, nil, 0.5, 9] |> Enum.with_index(), reduce: config do
        config ->
          x = 60 + rem(i, 3) * 245
          y = 100 + div(i, 3) * 160

          config
          |> Flex.LiveScreen.add({x + 0, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, 6.0},
            error: {1.0, 8.0},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 30, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {nil, 6.0},
            error: {1.0, 8.0},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 60, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, 6.0},
            error: {nil, 8.0},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 90, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {nil, 6.0},
            error: {nil, 8.0},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 120, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, nil},
            error: {1.0, 8.0},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 150, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, 6.0},
            error: {1.0, nil},
            value: {:const, v}
          )
          |> Flex.LiveScreen.add({x + 180, y}, Flex.MovingAnalogIndicator,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, nil},
            error: {1.0, nil},
            value: {:const, v}
          )
      end
    end).()
|> Flex.LiveScreen.run()

:ok
