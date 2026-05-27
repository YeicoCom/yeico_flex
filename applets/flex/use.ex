defmodule Flex.Use do
  use Terminal

  defmacro __using__(_) do
    quote do
      use Terminal
      alias Flex.Db
      alias Flex.UI
      alias Flex.Logs
      alias Flex.Login
      alias Flex.Modbus
      alias Flex.Points
    end
  end
end
