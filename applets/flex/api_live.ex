defmodule Flex.Live do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      use Flex
    end
  end
end
