defmodule Flex.BackendApp do
  use Flex.Service
  use Terminal

  defp specs(),
    do: %{
      route: %{initial: nil, check: :binary},
      name: %{initial: nil, check: :binary?},
      env: %{initial: [], check: {:list, nil, {:tuple, 2, :binary}}}
    }

  defp setup(%{route: route, name: name, env: env}) do
    sid = Process.get(:__sid__)
    Log.debug("#{sid} starting")
    name = name || Path.basename(route, ".exs")
    {"", 0} = System.cmd("epmd", ["-daemon"])

    hostname = Api.hostname()
    init_args = :init.get_arguments()
    [lname] = Keyword.get(init_args, :name, [~c"terminal@#{hostname}.local"])
    lname = lname |> to_string() |> String.to_atom()
    cookie = Node.get_cookie() |> to_string()

    case Node.start(lname) do
      {:error, {:already_started, _}} -> :ok
      {:ok, _} -> :ok
      unexpected -> throw(unexpected)
    end

    # nerves fw erl misses dirname and other utils
    [progname] = Keyword.fetch!(init_args, :progname)
    [bindir] = Keyword.fetch!(init_args, :bindir)
    progname = Path.join(bindir, progname)

    path =
      case Terminal.dev?() do
        true -> Path.join(Api.path(), "#{name}/_build/dev")
        _ -> Path.join(Api.path(), "#{name}.app")
      end

    libs =
      [
        Path.join(path, "lib"),
        :code.lib_dir(:elixir) |> Path.dirname() |> Path.expand(),
        :code.lib_dir() |> Path.expand()
      ]
      |> Enum.uniq()
      |> Enum.join(":")

    # FIXME latin1 received regardless of passing UTF8 variables
    # LANGUAGE=en LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    #
    # Solved with ERL_AFLAGS=+fnu
    # latin1 warning: the VM is running with native name encoding of latin1 which may cause Elixir to malfunction
    # as it expects utf8. Please ensure your locale is set to UTF-8 (which can be verified by running "locale" in
    # your shell) or set the ELIXIR_ERL_OPTIONS="+fnu" environment variable
    env = [
      {"ERL_LIBS", libs},
      {"BACKEND_NAME", name},
      {"BACKEND_ROUTE", route},
      {"BACKEND_ENTRY", Api.entry()},
      {"BACKEND_COOKIE", cookie},
      {"BACKEND_NODE", Node.self() |> to_string()},
      {"BACKEND_TMP", Terminal.tmp()},
      {"BACKEND_ROOT", Terminal.root()},
      {"BACKEND_HOME", Terminal.home()},
      {"BACKEND_DEV", inspect(Terminal.dev?())},
      {"BACKEND_DEVICE", inspect(Terminal.device?())},
      {"BACKEND_APPLETS", Api.path()},
      {"ERL_AFLAGS", "+fnu"}
      | env
    ]

    # FIXME -proto_dist inet_tls
    # FIXME inet_dist_use_interface
    args = [
      "-pa",
      Flex.build(),
      "-noshell",
      "-setcookie",
      cookie,
      "-name",
      "#{name}@#{hostname}.local",
      "-s",
      "application",
      "ensure_all_started",
      name
    ]

    # required by nerves fw
    args =
      with [boot] <- Keyword.get(init_args, :boot),
           [boot_var, boot_val] <- Keyword.get(init_args, :boot_var) do
        boot = boot |> Path.dirname() |> Path.join("start_clean")
        ["-boot", "#{boot}", "-boot_var", "#{boot_var}", "#{boot_val}" | args]
      else
        _ -> args
      end

    wait(name, :pang)
    into = IO.binstream(self(), :line)
    opts = [into: into, stderr_to_stdout: true, env: env, cd: Terminal.home()]
    Api.async(fn -> MuonTrap.cmd(progname, args, opts) end)
    wait(name, :pong)
    loop(name)
  end

  defp loop(name) do
    receive do
      {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
        send(from, {:io_reply, reply_as, :ok})
        line = :unicode.characters_to_binary(line, encoding, :utf8)
        Log.trace("#{name}.app #{encoding} #{String.trim(line)}")
        loop(name)

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
