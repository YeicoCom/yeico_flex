use Terminal

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

:ok
