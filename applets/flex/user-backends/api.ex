defmodule Flex.Backend.Log do
  def trace(msg), do: log("trace", msg)
  def debug(msg), do: log("debug", msg)
  def info(msg), do: log("info", msg)
  def warn(msg), do: log("warn", msg)
  def error(msg), do: log("error", msg)

  defp log(level, msg) when is_binary(msg) do
    IO.puts([level, " ", msg])
    msg
  end

  defp log(level, msg) do
    log(level, inspect(msg))
    msg
  end
end

defmodule Flex.Backend do
  defmacro __using__(_) do
    quote do
      alias Flex.Backend.Log
    end
  end
end
