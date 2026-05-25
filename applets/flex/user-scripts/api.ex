defmodule Flex.Script do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      alias Flex.Point
    end
  end
end
