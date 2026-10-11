defmodule Flex do
  use Terminal

  # wrap only required from non applet processes like render
  # wrap required for logs and stacktraces
  # Api.wrap logs unhandled exceptions
  # Api.wrapper() does not
  def wrap(fun) do
    wrapper = Api.wrapper()
    wrapper.(fun)
  end
end
