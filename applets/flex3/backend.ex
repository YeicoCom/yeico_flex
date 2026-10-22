defmodule Flex.Backend do
  defmacro __using__(_) do
    quote do
      alias Flex.Backend.Log
      alias Flex.Backend.Api
    end
  end

  defmodule Api do
    def var(name), do: System.get_env("BACKEND_#{name}")
    def name(), do: var("NAME")
    def master(), do: var("NODE")
    def entry(), do: var("ENTRY")
    def route(), do: var("ROUTE")
    def home(), do: var("HOME")

    def connect() do
      master = master() |> String.to_atom()
      true = master |> Node.connect()
      master
    end

    def inspect?(term) when is_binary(term), do: term

    def inspect?(term) do
      inspect(term,
        limit: :infinity,
        width: :infinity,
        printable_limit: :infinity
      )
    end

    def call(mod, fun, args) do
      Api.connect() |> :rpc.call(mod, fun, args)
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
  end

  defmodule Log do
    alias Flex.Backend.Api

    def log(level, term) do
      entry = Api.entry()
      route = Api.route()
      name = Api.name()
      line = "#{route} #{Api.inspect?(name)}/#{Api.inspect?(self())} #{Api.inspect?(term)}"
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
