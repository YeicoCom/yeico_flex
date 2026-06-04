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
      def call(:start, entity), do: start(entity)
      def call(:clean, entity), do: clean(entity)
    end
  end

  alias Flex2.Utils
  alias Flex2.Async
  alias Flex2.Log

  def get(prop), do: Async.ctx()[prop]

  def root(module) do
    hash = get(:id) |> Utils.md5()
    Utils.dpath("@run/flex2/#{Log.inspect?(module)}-#{hash}")
  end

  # def error(value) when is_binary(value) do
  #   alias Applet.Api
  #   id = get(:id)
  #   key = "entity:error:#{id}"
  #   Api.putcast!(key, value)
  # end
end
