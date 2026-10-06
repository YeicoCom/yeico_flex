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

Flex3.EchoServer.new()
|> Flex3.EchoServer.set(ip: "127.0.0.1")
|> Flex3.EchoServer.set(port: 4021)
|> Flex3.EchoServer.run()

Flex3.ModbusSlave.new()
|> Flex3.ModbusSlave.set(key: "modbus:slave:tcp")
|> Flex3.ModbusSlave.set(proto: "TCP")
|> Flex3.ModbusSlave.set(ip: "127.0.0.1")
|> Flex3.ModbusSlave.set(port: 4031)
|> Flex3.ModbusSlave.run()

Flex3.ModbusSlave.new()
|> Flex3.ModbusSlave.set(key: "modbus:slave:rtu")
|> Flex3.ModbusSlave.set(proto: "RTU")
|> Flex3.ModbusSlave.set(ip: "127.0.0.1")
|> Flex3.ModbusSlave.set(port: 4032)
|> Flex3.ModbusSlave.run()

Flex3.ShellCommand.new()
|> Flex3.ShellCommand.set(id: "socat_pair")
|> Flex3.ShellCommand.set(
  run: """
  # do not use -9 or sudo wont kill child socat process
  [ -f $FLEX3_RUN/socat_pair.pid ] && sudo kill $(cat $FLEX3_RUN/socat_pair.pid)
  sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B &
  echo $! > $FLEX3_RUN/socat_pair.pid
  # System.shell waits for background processes with trailing &
  """
)
|> Flex3.ShellCommand.set(
  kill: """
  # do not use -9 or sudo wont kill child socat process
  [ -f $FLEX3_RUN/socat_pair.pid ] && sudo kill $(cat $FLEX3_RUN/socat_pair.pid)
  """
)
|> Flex3.ShellCommand.run(rdms: 1000)

Flex3.SerialExport.new()
|> Flex3.SerialExport.set(tty: "/tmp/tty.socat.A")
|> Flex3.SerialExport.set(port: 4041)
|> Flex3.SerialExport.run(rdms: 1000)

# test with:
# Adb.list
# Adb.put("flex:point:sink:bit:D0", 1)
# Adb.put("flex:point:sink:bit:D0", 0)
# Adb.put("flex:point:sink:uint16:R0", 0)
# Adb.put("flex:point:sink:uint16:R0", 2)
Flex3.ModbusDevice.new()
|> Flex3.ModbusDevice.set(name: "moddev1")
|> Flex3.ModbusDevice.set(ip: "127.0.0.1")
|> Flex3.ModbusDevice.set(port: 4031)
|> Flex3.ModbusDevice.set(proto: "TCP")
|> Flex3.ModbusDevice.set(
  points: [
    %{type: "WDO", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"},
    %{type: "RDI", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"},
    %{type: "WRO", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"},
    %{type: "RRI", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"}
  ]
)
|> Flex3.ModbusDevice.run(rdms: 1000)

:ok
