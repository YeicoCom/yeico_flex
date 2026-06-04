defmodule Flex2.Super do
  use Terminal
  alias Flex2.Runner
  alias Flex2.Async
  alias Flex2.Utils

  def start() do
    stamp = Utils.stamp()
    name = Utils.inspect?(__MODULE__)
    Async.spawn("#{stamp}:#{name}", &setup/0)
  end

  def start(module, entity, opts) do
    module.set(entity, Map.merge(module.new(), entity))
    context = %{module: module, entity: entity, opts: opts}
    pid = Utils.pid(__MODULE__)
    send(pid, {:start, self(), context})

    receive do
      {:start, result} -> result
    after
      5_000 -> throw(timeout: {:start, context})
    end
  end

  def stop(id) do
    pid = Utils.pid(__MODULE__)
    send(pid, {:stop, self(), id})

    receive do
      {:stop, result} -> result
    after
      5_000 -> throw(timeout: {:stop, id})
    end
  end

  def state() do
    pid = Utils.pid(__MODULE__)
    send(pid, {:state, self()})

    receive do
      {:state, result} -> result
    after
      5_000 -> throw(timeout: :state)
    end
  end

  # lets see how far can a single async go without
  # restarting the applet from within a defer
  defp setup() do
    Process.register(self(), __MODULE__)
    Process.flag(:trap_exit, true)
    loop(%{})
  end

  defp loop(state) do
    receive do
      {:start, caller, args = %{module: module, entity: entity, opts: opts}} ->
        result = Api.safe(fn -> Runner.run(module, entity, Utils.id(), opts) end)
        state = append(state, caller, args, result)
        loop(state)

      {:stop, caller, id} ->
        context = state[id]
        kill(context)
        state = Map.delete(state, id)
        state = Map.delete(state, context[:task][:pid])
        send(caller, {:stop, {:ok, id}})
        loop(state)

      {:state, caller} ->
        send(caller, {:state, state})
        loop(state)

      {:EXIT, pid, reason} ->
        id = state[pid]
        # only important if it is a registered entity
        if id, do: Log.error(exited: reason, context: state[id])
        loop(state)

      unexpected ->
        Log.warn(unexpected: unexpected)
        loop(state)
    end
  end

  defp append(state, caller, %{module: module}, {:error, %{error: error, type: type}}) do
    Log.error("#{Api.inspect?(module)} #{type} #{Api.inspect?(error)}")
    send(caller, {:start, {:error, error}})
    state
  end

  defp append(state, caller, _, {:ok, context = %{id: id, task: %{pid: pid}}}) do
    send(caller, {:start, {:ok, id}})
    state = Map.put(state, id, context)
    state = Map.put(state, pid, id)
    state
  end

  defp kill(nil), do: :nop
  defp kill(context), do: Runner.kill(context)
end
