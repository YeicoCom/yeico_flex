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

      def new(opts \\ []), do: Flex2.Setter.set(__MODULE__, initial(), opts)
      def set(entity, opts), do: Flex2.Setter.set(__MODULE__, entity, opts)
      def set(entity, name, value), do: Flex2.Setter.set(entity, name, value, checks())
      def run(entity, opts \\ []), do: Flex2.Super.start(__MODULE__, entity, opts)
      def call(:start, entity, ctx), do: start(entity, ctx)
      def call(:clean, entity, ctx), do: clean(entity, ctx)
    end
  end

  alias Flex2.Utils
  alias Flex2.Log

  def root(module, id) do
    hash = Utils.md5(id)
    Utils.dpath("@run/flex2/#{Log.inspect?(module)}-#{hash}")
  end
end
