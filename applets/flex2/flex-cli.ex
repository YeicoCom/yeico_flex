defmodule Flex2.Cli do
  alias Flex2.Utils

  def kill?(name) when is_binary(name), do: Utils.kill?(name)
  def whereis?(name) when is_binary(name), do: Utils.whereis?(name)
end
