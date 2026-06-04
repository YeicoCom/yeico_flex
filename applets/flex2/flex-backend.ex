defmodule Flex2.Backend.Log do
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

defmodule Flex2.Backend.Utils do
  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def sleep(), do: Process.sleep(:infinity)
  def sleep(millis), do: Process.sleep(millis)
  def receive(), do: receive(do: (msg -> msg))
  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)
end

defmodule Flex2.Backend.Environ do
  def hostname(), do: System.get_env("FLEX2_HOST")
  def master(), do: System.get_env("FLEX2_MASTER")
  def home(), do: System.get_env("FLEX2_HOME")
end

defmodule Flex2.Backend do
  defmacro __using__(_) do
    quote do
      alias Flex2.Backend.Log
      alias Flex2.Backend.Utils
      alias Flex2.Backend.Environ
    end
  end
end
