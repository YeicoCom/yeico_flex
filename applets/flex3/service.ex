defmodule Flex3.Service do
  defmacro __using__(_) do
    quote do
      use Terminal
      alias Flex3.Log
      alias Flex3.Service
      import Flex3.Log, only: [inspect?: 1]

      def new(opts \\ []),
        do: Service.set(checks(), initial(), opts)

      def set(config, opts),
        do: Service.set(checks(), config, opts)

      # opts: rdms, level, tag
      def run(config, opts \\ []),
        do: Service.run(&name/1, &setup/1, config, opts)

      def kill(task),
        do: Service.kill(task)
    end
  end

  use Terminal
  alias Flex3.Check

  def set(checks, config, opts) do
    for {name, value} <- opts, reduce: config do
      config ->
        params = checks[name]
        if !params, do: Check.abort(name, value, "not found")
        Check.check(name, value, params)
        Map.put(config, name, value)
    end
  end

  def run(name, setup, config, opts) do
    opts = Keyword.put_new(opts, :tag, name.(config))
    Api.loop(setup, config, opts)
  end

  def kill(task) do
    Api.kill(task)
  end
end
