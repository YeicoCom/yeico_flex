defmodule Flex.BackendExs do
  use Flex.Service
  use Terminal

  defp specs(),
    do: %{
      route: %{initial: nil, check: :binary},
      name: %{initial: nil, check: :binary?},
      args: %{initial: [], check: {:list, nil, :binary}},
      env: %{initial: [], check: {:list, nil, {:tuple, 2, :binary}}}
    }

  defp setup(%{route: route, name: name, args: args, env: env}) do
    Flex.Backend.Api.lo_alias()
    sid = Process.get(:__sid__)
    Log.debug("#{sid} starting")
    name = name || Path.basename(route, ".exs")
    {"", 0} = System.cmd("epmd", ["-daemon"])

    hostname = Api.hostname()
    init_args = :init.get_arguments()
    [lname] = Keyword.get(init_args, :name, [~c"terminal@#{hostname}.local"])
    lname = lname |> to_string() |> String.to_atom()

    case Node.start(lname) do
      {:error, {:already_started, _}} -> :ok
      {:ok, _} -> :ok
      unexpected -> throw(unexpected)
    end

    # node start changes the :nocookie default
    cookie = Node.get_cookie() |> to_string()

    env = [
      {"BACKEND_NAME", name},
      {"BACKEND_COOKIE", cookie},
      {"BACKEND_ROUTE", route},
      {"BACKEND_ENTRY", Api.entry()},
      {"BACKEND_NODE", Node.self() |> to_string()},
      {"BACKEND_TMP", Terminal.tmp()},
      {"BACKEND_ROOT", Terminal.root()},
      {"BACKEND_HOME", Terminal.home()},
      {"BACKEND_DEV", inspect(Terminal.dev?())},
      {"BACKEND_DEVICE", inspect(Terminal.device?())},
      {"BACKEND_APPLETS", Api.path()}
      | env
    ]

    args =
      [
        "-pa",
        Flex.build(),
        "--cookie",
        cookie,
        "--name",
        "#{name}@#{hostname}.local",
        Api.path(route)
        | args
      ]

    wait(name, :pang)
    into = IO.binstream(self(), :line)
    opts = [into: into, stderr_to_stdout: true, env: env, cd: Terminal.home()]
    Api.async(fn -> MuonTrap.cmd("elixir", args, opts) end)
    wait(name, :pong)
    loop(name)
  end

  defp loop(name) do
    receive do
      {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
        send(from, {:io_reply, reply_as, :ok})
        line = :unicode.characters_to_binary(line, encoding, :utf8)
        Log.trace("#{name}.exs #{encoding} #{String.trim(line)}")
        loop(name)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  # nerves fw node wont auto connect
  # fake ping to leave connection optional
  defp wait(name, res) do
    name = name |> to_charlist()

    fun = fn ->
      {:ok, names} = :net_adm.names()
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
