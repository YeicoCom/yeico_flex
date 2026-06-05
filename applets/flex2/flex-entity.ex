defmodule Flex2.Entity do
  defmacro __using__(_) do
    quote do
      alias Flex2.Entity
      alias Flex2.Setter
      alias Flex2.Status
      alias Flex2.Utils
      alias Flex2.Async
      alias Flex2.Live
      alias Flex2.Log

      def new(opts \\ []), do: Setter.set(__MODULE__, initial(), opts)
      def set(entity, opts), do: Setter.set(__MODULE__, entity, opts)
      def set(entity, name, value), do: Setter.set(entity, name, value, checks())
      def run(entity, opts \\ []), do: Entity.run(__MODULE__, entity, opts)
      def call(:start, entity, ctx), do: start(entity, ctx)
      def call(:clean, entity, ctx), do: clean(entity, ctx)
    end
  end

  alias Flex2.Runner
  alias Flex2.Utils
  alias Flex2.Log

  def run(module, entity, opts \\ []) do
    module.set(entity, Map.merge(module.new(), entity))

    case Utils.safe(fn -> Runner.run(module, entity, Utils.id(), opts) end) do
      {:error, %{error: error, type: type, stack: stack}} ->
        msg = "#{Log.inspect?(module)} #{type} #{Log.inspect?(error)} #{Log.inspect?(stack)}"
        Log.error(msg)
        {:error, error}

      {:ok, context} ->
        {:ok, context}
    end
  end
end
