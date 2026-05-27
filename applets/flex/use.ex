defmodule Flex.Use do
  use Terminal

  defmacro __using__(_) do
    quote do
      use Terminal
      alias Flex.Db
      alias Flex.Mb
      alias Flex.Pt
      alias Flex.UI
      alias Flex.Lg
      alias Flex.Ln
    end
  end
end
