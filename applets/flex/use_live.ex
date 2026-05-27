defmodule Flex.Use.Live do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      use Flex.Use
    end
  end
end
