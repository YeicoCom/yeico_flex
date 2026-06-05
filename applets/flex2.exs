use Terminal

Api.path()
|> Path.join("flex2/_build")
|> (fn build ->
      Code.delete_path(build)
      Code.append_path(build)
    end).()

Api.path()
|> Path.join("flex2/_build/*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  :code.purge(m)
  :code.load_file(m)
end)

Adb.reset()

# fresh start since socat pid is not atomic
# clean = fn -> System.shell("sudo killall -9 socat", stderr_to_stdout: true) end
# Api.defer(clean)
# clean.()

# ~/.terminal/dev/flex2/repo
repo = Terminal.dpath("@home/flex2/repo")

Flex2.Repo.new(root: repo)
|> Flex2.Repo.run(name: "repo")

Flex2.Buffer.new(repo: "repo")
|> Flex2.Buffer.run(name: "buffer", deps: ["repo"])

Flex2.Daemon.new(repo: "repo")
|> Flex2.Daemon.run(name: "daemon", deps: ["buffer"])

# Flex2.ObservableMap.new()
# |> Flex2.ObservableMap.run(name: "adb")

# Flex2.ShellCommand.new()
# |> Flex2.ShellCommand.set(
#   run: """
#   sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B &
#   echo $! > $FLEX2_RUN/socat.pid
#   """
# )
# |> Flex2.ShellCommand.set(
#   kill: """
#   # do not use -9 or sudo wont kill child socat process
#   [ -f $FLEX2_RUN/socat.pid ] && sudo kill $(cat $FLEX2_RUN/socat.pid)
#   """
# )
# |> Flex2.ShellCommand.run(rdms: 2_000)

# Flex2.SerialExport.new()
# |> Flex2.SerialExport.set(tty: "/tmp/tty.socat.A")
# |> Flex2.SerialExport.set(port: 4_001)
# |> Flex2.SerialExport.run(rdms: 2_000)

# Flex2.SerialExport.new()
# |> Flex2.SerialExport.set(tty: "/tmp/tty.socat.B")
# |> Flex2.SerialExport.set(port: 4_002)
# |> Flex2.SerialExport.run(rdms: 2_000)

# Flex2.EchoServer.new()
# |> Flex2.EchoServer.set(port: 40_001)
# |> Flex2.EchoServer.run(rdms: 2_000)

Flex2.Live.view("/flex2", Flex2.View.handler(path: "/flex2", repo: repo))

# if Terminal.dev?(), do: Api.evalf("flex2/dev.exs")

if System.get_env("FLEX2_TEST") do
  Api.evalf("flex2/test.exs")
end

:ok
