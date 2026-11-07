defmodule Flex.Backend do
  defmacro __using__(_) do
    quote do
      alias Flex.Backend.Log
      alias Flex.Backend.Api
    end
  end

  defmodule Api do
    def var(name), do: System.get_env(name)
    def var(name, value), do: System.put_env(name, value)
    def app(), do: var("BACKEND_APP")
    def name(), do: var("BACKEND_NAME")
    def master(), do: var("BACKEND_NODE")
    def entry(), do: var("BACKEND_ENTRY")
    def route(), do: var("BACKEND_ROUTE")
    def home(), do: var("BACKEND_HOME")
    def cookie(), do: var("BACKEND_COOKIE")

    def path(), do: var("BACKEND_APPLETS")
    def path(route), do: Path.join(path(), route)
    def dev?(), do: var("BACKEND_DEV") == "true"
    def device?(), do: var("BACKEND_DEVICE") == "true"

    def connect() do
      master = master() |> String.to_atom()
      # fails first time on just rebooted vm
      await(fn -> Node.connect(master) end)
      master
    end

    def pid(%Task{pid: pid}), do: pid

    def sleep(), do: Process.sleep(:infinity)
    def sleep(millis), do: Process.sleep(millis)

    def receive(), do: receive(do: (msg -> msg))
    def receive(msg), do: receive(do: (^msg -> :ok))

    @inspect [limit: :infinity, width: :infinity, printable_limit: :infinity]

    def printable(term, replacement \\ "") do
      case is_binary(term) do
        true ->
          case String.printable?(term) do
            false -> String.replace(term, ~r/\p{C}/u, replacement)
            true -> term
          end

        false ->
          inspect(term, @inspect)
      end
    end

    # IO.puts of non printable throws
    def inspect?(term) do
      case is_binary(term) and String.printable?(term) do
        false -> inspect(term, @inspect)
        true -> term
      end
    end

    def call(mod, fun, args) do
      connect() |> :rpc.call(mod, fun, args)
    end

    def putcast!(key, value) do
      call(Applet.Api, :putcast!, [key, value])
    end

    def dpath(path) do
      call(Terminal, :dpath, [path])
    end

    def fpath(path) do
      call(Terminal, :fpath, [path])
    end

    def hostname() do
      {:ok, host} = :inet.gethostname()
      to_string(host)
    end

    def hostname_f() do
      {hostname, 0} = System.cmd("hostname", ["-f"])
      hostname |> String.trim()
    end

    def resolve(host) do
      with {:ok, {a, b, c, d}} <- :inet.getaddr(~c"#{host}", :inet) do
        {:ok, "#{a}.#{b}.#{c}.#{d}"}
      end
    end

    def defer(fun) when is_function(fun, 0), do: defer(self(), fun)

    def defer(fun, arg) when is_function(fun, 1), do: defer(self(), fn -> fun.(arg) end)

    def defer(pid, fun) when is_pid(pid) and is_function(fun, 0) do
      # spawn to avoid sudden death
      spawn(fn ->
        ref = Process.monitor(pid)

        receive do
          {:DOWN, ^ref, _, ^pid, _} -> safe(fun)
        end
      end)
    end

    def defer(pid, fun, arg) when is_pid(pid) and is_function(fun, 1),
      do: defer(pid, fn -> fun.(arg) end)

    def safe(fun) when is_function(fun, 0) do
      try do
        {:ok, fun.()}
      rescue
        error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
      catch
        error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
      end
    end

    def safe(fun, arg) when is_function(fun, 1) do
      try do
        {:ok, fun.(arg)}
      rescue
        error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
      catch
        error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
      end
    end

    def kill(%Task{pid: pid}), do: kill(pid)

    def kill(pid) when is_pid(pid) do
      Process.unlink(pid)
      Process.exit(pid, :kill)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, ^pid, _} -> :ok
      end

      # not a reference
      # Process.demonitor(pid)
    end

    # Task.await forwards exit signals making it not suitable for loops
    def await(%Task{ref: ref, owner: owner} = task) do
      if owner != self() do
        raise ArgumentError, "#{inspect(self())} is not the owner of #{inspect(task)}"
      end

      receive do
        {^ref, reply} ->
          Process.demonitor(ref, [:flush])
          {:ok, reply}

        {:DOWN, ^ref, _, proc, reason} ->
          {:error, %{error: :down, reason: reason, proc: proc, task: task}}
      end
    end

    def await(fun, sms \\ 100) do
      case fun.() do
        true ->
          :ok

        _ ->
          Process.sleep(sms)
          await(fun, sms)
      end
    end
  end

  defmodule Log do
    alias Flex.Backend.Api

    def log(level, term) do
      entry = Api.entry()
      route = Api.route()
      name = Api.name()
      line = "#{route} #{name}/#{Api.inspect?(self())} #{Api.inspect?(term)}"
      Api.call(Applet, :broadcast!, [entry, level, line])
      term
    end

    def trace(term), do: log(:trace, term)
    def debug(term), do: log(:debug, term)
    def info(term), do: log(:info, term)
    def warn(term), do: log(:warn, term)
    def error(term), do: log(:error, term)
  end
end
