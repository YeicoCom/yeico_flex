defmodule Flex2.ElixirBackend do
  use Flex2.Entity

  defp initial() do
    %{
      code: nil
    }
  end

  defp checks() do
    %{
      code: :binary
    }
  end

  defp clean(_, %{root: root}) do
    File.rm_rf(root)
  end

  # do not give a permanent home or clean would need to leave
  # things behind, backends must work on temporary storage only
  defp start(%{code: code}, %{root: root, hash: hash}) do
    node = "backend_#{hash}"
    libs = Utils.dpath("#{root}/libs")
    beams = Utils.path("flex2/_build/Elixir.Flex2.Backend*.beam")
    System.shell("rsync -avr --delete #{beams} #{libs}/ebin/")
    path = Utils.fpath("#{root}/backend.exs")
    File.write!(path, code)
    {"", 0} = System.cmd("epmd", ["-daemon"])
    home = Utils.dpath("#{root}/home")

    # :init.get_arguments()[:name]
    # nil in nerves vm110
    # terminal@mbair.local in macos m1
    # terminal@vps04.local in flex.yeico.com
    hostname = Utils.hostname()
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
      # {"LANG", "en_US.UTF-8"},
      # {"LC_ALL", "en_US.UTF-8"},
      # {"ELIXIR_ERL_OPTIONS", "+fnu"},
      {"FLEX2_MASTER", Node.self() |> to_string()},
      {"FLEX2_HOST", hostname},
      {"FLEX2_SCRIPT", path},
      {"FLEX2_HOME", home},
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
    opts = [into: into, stderr_to_stdout: true, env: env, cd: home]

    tag = "#{Async.tag()}:elixir"

    Async.spawn(tag, fn ->
      {_res, code} = MuonTrap.cmd("elixir", args, opts)
      # elixir exits on compile errors before wait on pong returns below
      # explicit process kill on elixir return to avoid infinite loop
      Log.warn("Exited with code #{code}")
      exit(:kill)
    end)

    wait(node, :pong)
    Process.put(:pid?, false)
    loop()
    exit(:kill)
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

    Utils.until(fun)
  end

  defp loop() do
    receive do
      {:io_request, from, reply_as, {:put_chars, encoding, text}} ->
        send(from, {:io_reply, reply_as, :ok})

        # mbair stdout received as latin1
        #   garbage on compile errors (solved by removing trim below)
        #     - due to missing ascii box-drawing characters
        #     - not applying lines = :unicode.characters_to_binary(text, encoding, :utf8) shows them
        #     - not ansi escapes as originally supposed (there may be one, the ^ is red)
        #   :epp.default_encoding() -> utf8
        #   :file.native_name_encoding() -> utf8
        # lines = :unicode.characters_to_binary(text, encoding, :utf8)
        lines = text

        # output for unknown variable a in line 9
        # latin1 20202020error:20undefined20variable20"a"
        # latin1 20202020E29482
        # latin1 2020920E2948220a
        # latin1 20202020E2948220^
        # latin1 20202020E29482

        for line <- String.split(lines, "\n", trim: true) do
          # do not trim or compile errors wont render correctly
          case line do
            "trace " <> tail -> Log.trace(tail)
            "debug " <> tail -> Log.debug(tail)
            "info " <> tail -> Log.info(tail)
            "warn " <> tail -> Log.warn(tail)
            "error " <> tail -> Log.error(tail)
            stdout -> Log.trace("#{encoding} #{stdout}")
          end
        end

        loop()

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end
end
