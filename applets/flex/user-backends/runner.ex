defmodule Flex.UserBackends.Runner do
  use Terminal

  def clean(id) do
    File.rm_rf!(Terminal.dpath("@run/flex/backend_#{id}"))
    File.rm_rf!(Terminal.fpath("@run/flex/backend_#{id}.exs"))
  end

  def run(id, name, code) do
    node = "backend_#{id}"
    libs = Terminal.dpath("@run/flex/#{node}")
    beams = Path.join(Api.path(), "flex/_build/Elixir.Flex.Backend*.beam")
    System.shell("rsync -avr --delete #{beams} #{libs}/ebin/")
    path = Terminal.fpath("@run/flex/#{node}.exs")
    File.write!(path, code)
    {"", 0} = System.cmd("epmd", ["-daemon"])

    hostname = Api.hostname()
    init_args = :init.get_arguments()
    [lname] = Keyword.get(init_args, :name, [~c"terminal@#{hostname}.local"])
    lname = lname |> to_string() |> String.to_atom()
    cookie = Node.get_cookie() |> to_string()

    case Node.start(lname) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
      unexpected -> throw(unexpected)
    end

    env = [
      {"TERMINAL_NODE", Node.self() |> to_string()},
      {"TERMINAL_TMP", Terminal.tmp()},
      {"TERMINAL_ROOT", Terminal.root()},
      {"TERMINAL_HOME", Terminal.home()},
      {"TERMINAL_HOST", Api.hostname()},
      {"ERL_LIBS", libs}
    ]

    args = [
      "--cookie",
      cookie,
      "--name",
      "#{node}@#{hostname}.local",
      path
    ]

    wait(node, :pang)
    into = IO.binstream(self(), :line)
    opts = [into: into, stderr_to_stdout: true, env: env, cd: Terminal.home()]

    tag = "userbackends:#{id}:#{name}:elixir"

    fun = fn ->
      {_res, code} = MuonTrap.cmd("elixir", args, opts)
      Log.warn("Exited with code #{code}")
      Process.exit(self(), :kill)
    end

    Api.async(fun, tag: tag)
    wait(node, :pong)
    loop(id)
    Process.exit(self(), :kill)
  end

  defp loop(id) do
    receive do
      {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
        send(from, {:io_reply, reply_as, :ok})
        # line = :unicode.characters_to_binary(line, encoding, :utf8)

        for line <- String.split(line, "\n", trim: true) do
          case line do
            "trace " <> tail -> Log.trace(tail)
            "debug " <> tail -> Log.debug(tail)
            "info " <> tail -> Log.info(tail)
            "warn " <> tail -> Log.warn(tail)
            "error " <> tail -> Log.error(tail)
            stdout -> Log.trace("#{encoding} #{stdout}")
          end
        end

        loop(id)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  # nerves fw node wont auto connect
  # fake ping to leave connection optional
  defp wait(name, res, toms \\ 5_000) do
    name = name |> to_charlist()
    local = ~c"127.0.0.1"

    fun = fn ->
      {:ok, names} = :net_adm.names(local)
      names = Enum.into(names, %{})

      res ==
        case Map.has_key?(names, name) do
          false -> :pang
          true -> :pong
        end
    end

    # mountrap stuck after several attemps to run a backend with compile errors
    # last resource task await timeout kills the calling process on timeout
    task = Api.async(fn -> Api.await(fun) end)
    Api.await(task, toms)
  end
end
