defmodule Flex.Service do
  defmacro __using__(_) do
    quote do
      alias Applet.Api
      alias Applet.Api.Mdb

      def new(opts \\ []) do
        specs()
        |> Flex.Config.initial()
        |> Flex.Config.merge(opts)
      end

      def set(config, opts) do
        Flex.Config.merge(config, opts)
      end

      # opts:
      #   loop -> rdms \\ 0, level, tag
      #   service -> name, deps
      def run(config, opts \\ []) do
        {deps, opts} = Keyword.pop(opts, :deps)
        {name, opts} = Keyword.pop(opts, :name)
        opts = Keyword.put_new(opts, :tag, name(config))
        config = Flex.Config.compile(__MODULE__, specs(), config)

        setup = fn config ->
          par = Process.get(:__par__)
          Api.await(fn -> [] == Mdb.lookup({:clean, par}) end)
          if length(deps) > 0, do: Api.await(fn -> wait(deps) end)
          Process.put(:__name__, name)
          setup(config)
        end

        Api.loop(setup, config, opts)
      end

      defp wait(deps) do
        self = self()
        tag = Process.get(:__tag__)
        pids = for name <- deps, do: Mdb.lookup({:service, name})

        if Enum.all?(pids, fn list -> length(list) > 0 end) do
          tag = String.trim_trailing(tag, ":setup")
          pids = List.flatten(pids)

          Api.async(
            fn ->
              for {pid, _} <- pids, do: Process.monitor(pid)
              Api.receive()
              Api.kill(self)
            end,
            tag: "#{tag}:deps"
          )

          true
        end
      end

      defp ready() do
        par = Process.get(:__par__)
        name = Process.get(:__name__)
        stamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:millisecond)
        Mdb.register!({:service, name}, par: par, stamp: stamp)
      end

      defp clean(clean, now? \\ false) do
        if now?, do: Api.safe(clean)
        name = Process.get(:__name__)
        par = Process.get(:__par__)
        setup = self()

        before = fn ->
          stamp = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:millisecond)
          Mdb.register!({:clean, par}, name: name, stamp: stamp)
          send(setup, :before)
        end

        task = Api.defer(clean, before: before)
        :ok = Api.receive(:before)
        task
      end
    end
  end

  alias Applet.Api
  alias Applet.Api.Mdb

  # stop by returned task
  def stop(%{pid: par}) when is_pid(par) do
    Api.kill(par)
    Api.await(fn -> [] == Mdb.lookup({:clean, par}) end)
  end

  # stop by service name (passed to run call)
  # for testing only: ignored while service restarting
  def stop(name) do
    for {_pid, opts} <- Mdb.lookup({:service, name}) do
      Api.kill(Keyword.get(opts, :par))
    end
  end

  # respawn by service name
  # for testing only: ignored while service restarting
  def kill(name) do
    for {pid, _} <- Mdb.lookup({:service, name}) do
      Api.kill(pid)
    end
  end
end
