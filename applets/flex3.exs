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
  fn ctx = %{state: state, inputs: inputs, event: event} ->
    # :mount, {:timer, :timer1}, {:point, :point1}
    if event == :mount, do: ctx.trace.("mount")
    %{const1: const1, timer1: timer1, point1: point1} = inputs
    value = (point1 || const1) * timer1
    Api.putcast!("logic1:calc1", value)
    state
  end,
  [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "logic1:point1"}}
  ]
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
|> Flex.LiveScreen.put(:class, "ls:main", "bg-gray-300 select-none")
|> Flex.LiveScreen.put(:class, "ls:panel", "bg-gray-600")
|> Flex.LiveScreen.set(
  style: """
  #ls_main:hover {
    background-color: blue;
  }
  #ls_panel:hover {
    background-color: black;
  }
  """
)
|> Flex.LiveScreen.add(
  [40, 20],
  fn
    # :mount, :render, {:timer, :timer1}, {:point, :point1}, {:event, "click", _params}
    # log confirmed to work in render callback
    %{state: assigns, event: :render} ->
      ~H"""
      <div class="text-[24px] text-red-500 w-[12em] p-2 bg-gray-800">
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
  end,
  [
    {:const1, {:const, -1}},
    {:timer1, {:timer, 100}},
    {:point1, {:point, "screen1:point1"}}
  ]
)
|> Flex.LiveScreen.add(
  [440, 20],
  fn
    %{state: state, shared: shared, event: :render} ->
      assigns = Map.put(state, :shared, shared)

      ~H"""
      <div class="text-[24px] text-red-500 w-[300px] p-2 bg-gray-800 cursor-pointer"
        phx-click="click" phx-value-index={@index}>
        Click me count: {@shared[:count]}
      </div>
      """

    %{state: state, event: :mount, put: put} ->
      put.(:count, 0)
      state

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
  [440, 80],
  fn
    %{state: state, shared: shared, event: :render} ->
      assigns = Map.put(state, :shared, shared)

      ~H"""
      <div class="text-[24px] text-red-500 w-[300px] p-2 bg-gray-800">
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
|> Flex.LiveScreen.put(:class, "ll:label", "text-blue-600 text-[24px]")
|> Flex.LiveScreen.put(:class, "ll:input", [
  "bg-blue-600 text-blue-400 text-[24px] text-center rounded-lg ring-0 focus:ring-0"
])
|> Flex.LiveScreen.add(
  [300, 200],
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
|> Flex.LiveScreen.run()

:ok
