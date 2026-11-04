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

    def sleep(), do: Process.sleep(:infinity)
    def sleep(millis), do: Process.sleep(millis)

    def receive(), do: receive(do: (msg -> msg))
    def receive(msg), do: receive(do: (^msg -> :ok))

    @inspect [limit: :infinity, width: :infinity, printable_limit: :infinity]

    def inspect?(term) do
      case is_binary(term) and String.printable?(term) do
        false -> inspect(term, @inspect)
        true -> term
      end
    end

    def printable(term) when is_binary(term) do
      String.replace(term, ~r/\p{C}/u, "")
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
