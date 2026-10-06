defmodule Flex.Entity do
  defmacro __using__(_) do
    quote do
      alias Flex.Entity
      alias Flex.Setter
      alias Flex.Utils
      alias Flex.Async
      alias Flex.Live
      alias Flex.Log

      def new(opts \\ []), do: Setter.set(__MODULE__, initial(), opts)
      def set(entity, opts), do: Setter.set(__MODULE__, entity, opts)
      def set(entity, name, value), do: Setter.set(entity, name, value, checks())
      def run(entity, opts \\ []), do: Entity.run(__MODULE__, entity, opts)
      def dispose(context), do: Entity.dispose(context)
      def call(:start, entity, ctx), do: start(entity, ctx)
      def call(:clean, entity, ctx), do: clean(entity, ctx)
    end
  end

  alias Flex.Runner
  alias Flex.Utils

  def run(module, entity, opts \\ []) do
    module.set(entity, Map.merge(module.new(), entity))
    Runner.run(module, entity, Utils.id(), opts)
  end

  def dispose(context), do: Runner.kill(context)
end
