defmodule Flex.Reactor do
  defmacro __using__(_) do
    quote do
      def new(opts \\ []) do
        specs()
        |> Flex.Config.initial()
        |> Flex.Config.merge(opts)
      end

      def build(config) do
        config = Flex.Config.compile(__MODULE__, specs(), config)
        %{handler: handler(config), inputs: inputs(config)}
      end
    end
  end

  use Terminal

  def check(path, value) do
    Flex.Check.check(path, value, {:tuple, 2})
    {mod, config} = value
    Flex.Check.check("#{path}.mod", mod, :atom)
    Flex.Check.check("#{path}.config", config, :map)
  end
end
