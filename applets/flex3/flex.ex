defmodule Flex do
  use Terminal

  # wrap only required from non applet processes like render
  # wrap required for logs and stacktraces
  # Api.wrap logs unhandled exceptions
  # Api.wrapper() does not
  def wrap(fun, wrapper \\ nil) do
    wrapper = wrapper || Api.wrapper()
    wrapper.(fun)
  end

  def trace(%{log: log}, term), do: log.(:trace, term)
  def debug(%{log: log}, term), do: log.(:debug, term)
  def info(%{log: log}, term), do: log.(:info, term)
  def warn(%{log: log}, term), do: log.(:warn, term)
  def error(%{log: log}, term), do: log.(:error, term)
end
