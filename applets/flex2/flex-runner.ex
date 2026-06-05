defmodule Flex2.Runner do
  alias Applet.Api.Mdb
  alias Applet.Api.Udb
  alias Flex2.Setter
  alias Flex2.Async
  alias Flex2.Utils
  alias Flex2.Log

  @stack false
  @take [:id, :name, :hash, :root]

  # clean callback expected idempotent and non process dependant
  def run(module, entity, id, opts) do
    # kill any pending clean since clean is the first task to go anyway
    Mdb.lookup({__MODULE__, id}) |> Enum.each(fn {pid, _} -> Utils.kill(pid) end)

    name = Keyword.get(opts, :name, nil)
    rdms = Keyword.get(opts, :rdms, 2_000)
    deps = Keyword.get(opts, :deps, [])
    log = Keyword.get(opts, :log, Async.ctx()[:log])

    # script users should only use rdms, name, and deps.
    # this is the public interface, do not use anything else
    Setter.check(:name, name, :binary?)
    Setter.check(:rdms, rdms, {:integer, 0, 65_535})
    Setter.check(:deps, deps, {:list?, nil, :binary})

    hash = Utils.md5(id)

    context = %{
      id: id,
      log: log,
      hash: hash,
      name: name,
      deps: deps,
      entity: entity,
      module: module,
      parent: self(),
      stamp: Utils.stamp(),
      mod?: Process.get(:mod?, false),
      root: Utils.expand("@run/flex2/#{Log.inspect?(module)}-#{hash}")
    }

    task = async(context, "super", fn -> setup(rdms, context) end)
    context = Map.put(context, :task, task)
    %{pid: pid} = async(context, "defer", fn -> defer(context) end)
    # fixme: what conditions may lock this initialization wait?
    Utils.receive({__MODULE__, pid, module, id})
    context
  end

  def kill(context = %{task: task}) do
    # not owner to await task when called from defer
    Utils.kill(task)
    task = async(context, "clean", fn -> call(:clean, context) end)
    Utils.await(task)
  end

  defp defer(context = %{task: %{pid: pid}, parent: parent}) do
    Process.flag(:trap_exit, true)
    ref = Process.monitor(pid)

    # schedule clean call on applet exit
    %{module: module, id: id, entity: entity} = context

    caller = self()

    defer =
      Async.defer(
        fn ->
          Async.ctx(context)
          Utils.kill(pid)
          ctx = Map.take(context, @take)
          Log.trace("clean")
          module.call(:clean, entity, ctx)
        end,
        before: fn ->
          Mdb.register!({__MODULE__, id}, module: module, role: "defer")
          send(parent, {__MODULE__, caller, module, id})
        end
      )

    receive do
      # entity super task is down
      {:DOWN, ^ref, :process, ^pid, _reason} -> :nop
      # parent exited leaving super task behind
      {:EXIT, _pid, _reason} -> kill(context)
    end

    # cancel defer
    Utils.kill(defer)
  end

  defp setup(rdms, context = %{id: id, stamp: stamp, module: module}) do
    Process.flag(:trap_exit, true)
    Mdb.register!(:entity, module: module, id: id, stamp: stamp)
    task = async(context, "clean", fn -> call(:clean, context) end)
    Utils.await(task)
    loop(rdms, context)
  end

  defp loop(rdms, context) do
    start = System.monotonic_time(:millisecond)
    task = async(context, "setup", fn -> call(:start, context) end)
    Utils.await(task)
    task = async(context, "clean", fn -> call(:clean, context) end)
    Utils.await(task)
    now = System.monotonic_time(:millisecond)
    Utils.flush(max(0, rdms - (now - start)))
    loop(rdms, context)
  end

  defp async(context = %{module: module, id: id, name: name}, role, fun) do
    stamp = Utils.stamp()
    module = Log.inspect?(module)
    wrap = wrap(role, context, fun)
    Async.spawn("#{stamp}:#{module}:#{id}:#{name}:#{role}", wrap)
  end

  defp wrap(role, %{module: module, id: id}, fun) do
    fn ->
      Mdb.register!({__MODULE__, id}, module: module, role: role)
      # Mdb.register!(__MODULE__, module: module, id: id, role: role)
      fun.()
    end
  end

  # forced kill to trigger managed resources cleanup
  # fixme: no stacktrace in logs to force improvement of error descriptions
  defp call(call, context = %{module: module, entity: entity, deps: deps}) do
    Async.ctx(context)
    # runner stack traces only required when developing an entity
    # scripts
    #   compile errors report the correct row
    #   match runtime error show the correct line in the stack trace
    #   nested?
    # backends
    #   compile errors report correct file and line over stdout (garbage due to unsupported ansi escapes?)
    #   match runtime error show the correct flie and line in a scarce stack trace
    try do
      Log.trace("#{call}")
      ctx = Map.take(context, @take)
      monitor(call, context, deps)
      register(call, context.name)
      module.call(call, entity, ctx)
    rescue
      error in RuntimeError ->
        Log.error("#{call} rescue: #{Log.inspect?(error.message)}")
        if @stack, do: Log.trace(Log.inspect?(__STACKTRACE__))

      error ->
        Log.error("#{call} rescue: #{Log.inspect?(error)}")
        if @stack, do: Log.trace(Log.inspect?(__STACKTRACE__))
    catch
      error ->
        Log.error("#{call} catch: #{Log.inspect?(error)}")
        if @stack, do: Log.trace(Log.inspect?(__STACKTRACE__))
    end

    exit(:kill)
  end

  defp monitor(_, _, []), do: :nop
  defp monitor(:clean, _, _), do: :nop

  defp monitor(:start, context, deps) do
    parent = self()
    pids = Enum.map(deps, &Utils.whereis/1)
    async(context, "deps", fn -> monitor(parent, pids) end)
  end

  defp monitor(parent, pids) do
    Process.monitor(parent)
    Enum.each(pids, &Process.monitor/1)
    Utils.receive()
    Process.exit(parent, :kill)
  end

  defp register(_, nil), do: :nop
  defp register(:clean, _), do: :nop
  defp register(:start, name), do: Udb.register!({:entity, name}, nil)
end
