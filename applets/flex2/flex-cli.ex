defmodule Flex2.Cli do
  alias Flex2.Utils

  # Flex2.Cli.kill?("repo")
  def kill?(name) when is_binary(name), do: Utils.kill?(name)

  # Flex2.Cli.whereis?("repo")
  def whereis?(name) when is_binary(name), do: Utils.whereis?(name)
end
