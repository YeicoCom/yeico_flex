defmodule Flex.Service do
  defmacro __using__(_) do
    quote do
      alias Flex.Check
      alias Applet.Api
      alias Applet.Api.Mdb

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

      # opts: rdms \\ 0, level, tag
      def run(config, opts \\ []) do
        config = Map.merge(initial(), config)
        config = set(initial(), config)
        opts = Keyword.put_new(opts, :tag, name(config))

        setup = fn config ->
          tag = Process.get(:__tag__)
          par = Process.get(:__par__)
          key = {:clean, __MODULE__, par}
          Api.await(fn -> [] == Mdb.lookup(key) end)
          stamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:millisecond)
          Mdb.register!({:setup, tag}, stamp: stamp)
          setup(config)
        end

        Api.loop(setup, config, opts)
      end

      def kill(%{pid: par}) do
        Api.kill(par)
        key = {:clean, __MODULE__, par}
        Api.await(fn -> [] == Mdb.lookup(key) end)
      end

      defp clean(clean, now? \\ false) do
        if now?, do: Api.safe(clean)
        par = Process.get(:__par__)
        key = {:clean, __MODULE__, par}
        setup = self()

        before = fn ->
          stamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:millisecond)
          Mdb.register!(key, setup: setup, stamp: stamp)
          send(setup, :before)
        end

        task = Api.defer(clean, before: before)
        :ok = Api.receive(:before)
      end
    end
  end

  alias Applet.Api
  alias Applet.Api.Mdb

  # tag from Flex.Print.tasks
  # Flex.Service.kill "modbus-slave:4031:127.0.0.1:TCP:setup"
  def kill(tag) when is_binary(tag) do
    for {pid, _} <- Mdb.lookup({:setup, tag}) do
      Api.kill(pid)
    end
  end
end
