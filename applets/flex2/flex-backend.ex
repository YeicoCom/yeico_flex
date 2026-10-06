defmodule Flex.Backend.Log do
  @opts [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def trace(msg), do: log("trace", msg)
  def debug(msg), do: log("debug", msg)
  def info(msg), do: log("info", msg)
  def warn(msg), do: log("warn", msg)
  def error(msg), do: log("error", msg)

  defp log(level, msg) when is_binary(msg) do
    IO.puts([level, " ", inspect(self()), " ", msg])
    msg
  end

  defp log(level, msg) do
    log(level, inspect(msg, @opts))
    msg
  end
end

defmodule Flex.Backend.Utils do
  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def sleep(), do: Process.sleep(:infinity)
  def sleep(millis), do: Process.sleep(millis)
  def receive(), do: receive(do: (msg -> msg))
  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)
end

defmodule Flex.Backend.Environ do
  def hostname(), do: System.get_env("FLEX_HOST")
  def master(), do: System.get_env("FLEX_MASTER")
  def home(), do: System.get_env("FLEX_HOME")
end

defmodule Flex.Backend do
  defmacro __using__(_) do
    quote do
      alias Flex.Backend.Log
      alias Flex.Backend.Utils
      alias Flex.Backend.Environ
    end
  end
end
