defmodule Flex.UserBackends.Runner do
  use Terminal

  def run(id, code) do
    name = "backend_#{id}"
    path = Terminal.fpath("@run/flex/#{name}.exs")
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
      {"TERMINAL_HOST", Api.hostname()}
    ]

    args = [
      "--cookie",
      cookie,
      "--name",
      "#{name}@#{hostname}.local",
      path
    ]

    wait(name, :pang)
    into = IO.binstream(self(), :line)
    opts = [into: into, stderr_to_stdout: true, env: env, cd: Terminal.home()]
    task = Api.async("userbackends:runner:#{id}", fn -> MuonTrap.cmd("elixir", args, opts) end)
    wait(name, :pong)
    loop(id, task)
  end

  defp loop(id, task = %{ref: ref}) do
    receive do
      {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
        send(from, {:io_reply, reply_as, :ok})
        lines = :unicode.characters_to_binary(line, encoding, :utf8)

        for line <- String.split(lines, "\n", trim: true) do
          case String.trim(line) do
            "trace " <> tail -> Log.trace(tail)
            "debug " <> tail -> Log.debug(tail)
            "info " <> tail -> Log.info(tail)
            "warn " <> tail -> Log.warn(tail)
            "error " <> tail -> Log.error(tail)
            stdout -> Log.trace("#{encoding} #{stdout}")
          end
        end

        loop(id, task)

      {^ref, {:ok, {_res, code}}} ->
        Log.warn("Exited with code #{code}")

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  # nerves fw node wont auto connect
  # fake ping to leave connection optional
  defp wait(name, res) do
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

    Api.await(fun)
  end
end
