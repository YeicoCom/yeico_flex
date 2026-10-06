use Terminal

Adb.reset()
# System.shell("sudo killall socat")

Api.evalf("flex3/code.exs")
Api.evalf("flex3/test/check.exs")

Flex3.EchoServer.new()
|> Flex3.EchoServer.set(ip: "127.0.0.1")
|> Flex3.EchoServer.set(port: 8_990)
|> Flex3.EchoServer.run()

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
|> Flex3.ShellCommand.run(rdms: 1_000)

Flex3.SerialExport.new()
|> Flex3.SerialExport.set(tty: "/tmp/tty.socat.A")
|> Flex3.SerialExport.set(port: 8_991)
|> Flex3.SerialExport.run(rdms: 1_000)

:ok
