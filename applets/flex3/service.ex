defmodule Flex3.Service do
  defmacro __using__(_) do
    quote do
      alias Flex3.Check
      alias Applet.Api
      alias Applet.Api.Mdb

      def new(opts \\ []), do: set(initial(), opts)

      def set(config, opts) do
        checks = checks()

        for {name, value} <- opts, reduce: config do
          config ->
            params = checks[name]
            if !params, do: Check.abort(name, value, "not found")
            Check.check(name, value, params)
            Map.put(config, name, value)
        end
      end

      # opts: rdms \\ 0, level, tag
      def run(config, opts \\ []) do
        config = Map.merge(initial(), config)
        config = set(initial(), config)
        opts = Keyword.put_new(opts, :tag, name(config))

        setup = fn config ->
          par = Process.get(:__par__)
          Api.await(fn -> [] == Mdb.lookup({:service, par}) end)
          setup(config)
        end

        Api.loop(setup, config, opts)
      end

      def kill(task = %{pid: par}) do
        Api.kill(task)
        Api.await(fn -> [] == Mdb.lookup({:service, par}) end)
      end

      defp clean(clean) do
        caller = self()
        par = Process.get(:__par__)

        before = fn ->
          Mdb.register!({:service, par}, caller)
          send(caller, :before)
        end

        task = Api.defer(clean, before: before)
        :ok = Api.receive(:before)
      end
    end
  end
end
