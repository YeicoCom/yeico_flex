defmodule Flex do
  use Applet.Alias

  def wrap(fun) do
    Api.wrapper().(fun)
  end
end
