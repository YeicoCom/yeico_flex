defmodule Flex.Widget do
  defmacro __using__(_) do
    quote do
      alias Flex.Check

      def new(opts \\ []), do: set(initial(), opts)

      def set(config, opts) do
        for {name, value} <- opts, reduce: config do
          config ->
            params = checks()[name]
            if !params, do: Check.abort(name, value, "not found")
            Check.check(name, value, params)
            Map.put(config, name, value)
        end
      end

      def fun(config) do
        config = Map.merge(initial(), config)
        config = set(initial(), config)
        {args(config), handler(config)}
      end
    end
  end
end
