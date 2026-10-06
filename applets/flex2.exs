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

Flex.Repo.new(root: repo)
|> Flex.Repo.run(name: "repo")

Flex.Buffer.new(repo: "repo")
|> Flex.Buffer.run(name: "buffer", deps: ["repo"])

Flex.Daemon.new(repo: "repo")
|> Flex.Daemon.run(name: "daemon", deps: ["buffer"])

# Flex.ObservableMap.new()
# |> Flex.ObservableMap.run(name: "adb")

# Flex.ShellCommand.new()
# |> Flex.ShellCommand.set(
#   run: """
#   sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B &
#   echo $! > $FLEX_RUN/socat.pid
#   """
# )
# |> Flex.ShellCommand.set(
#   kill: """
#   # do not use -9 or sudo wont kill child socat process
#   [ -f $FLEX_RUN/socat.pid ] && sudo kill $(cat $FLEX_RUN/socat.pid)
#   """
# )
# |> Flex.ShellCommand.run(rdms: 2_000)

# Flex.SerialExport.new()
# |> Flex.SerialExport.set(tty: "/tmp/tty.socat.A")
# |> Flex.SerialExport.set(port: 4_001)
# |> Flex.SerialExport.run(rdms: 2_000)

# Flex.SerialExport.new()
# |> Flex.SerialExport.set(tty: "/tmp/tty.socat.B")
# |> Flex.SerialExport.set(port: 4_002)
# |> Flex.SerialExport.run(rdms: 2_000)

# Flex.EchoServer.new()
# |> Flex.EchoServer.set(port: 40_001)
# |> Flex.EchoServer.run(rdms: 2_000)

Flex.Live.view("/flex2", Flex.View.handler(path: "/flex2", repo: repo), auth?: true)
Flex.Live.view("/flex2/", Flex.View.handler(path: "/flex2/", repo: repo), auth?: true)
Flex.Live.view("/flex2/login", Flex.Login.handler(path: "/flex2/login"))

# if Terminal.dev?(), do: Api.evalf("flex2/dev.exs")

if System.get_env("FLEX_TEST") do
  Api.evalf("flex2/test.exs")
end

:ok
