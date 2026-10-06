defmodule Flex.Cli do
  alias Flex.Utils

  # Flex.Cli.kill?("repo")
  def kill?(name) when is_binary(name), do: Utils.kill?(name)

  # Flex.Cli.whereis?("repo")
  def whereis?(name) when is_binary(name), do: Utils.whereis?(name)
end
