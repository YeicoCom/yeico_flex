defmodule Flex2.Runner do
  alias Applet.Api.Mdb
  alias Applet.Api.Udb
  alias Flex2.Setter
  alias Flex2.Async
  alias Flex2.Utils
  alias Flex2.Log

  @stack false

  # clean callback expected idempotent and non process dependant
  def run(module, entity, id, opts) do
    name = Keyword.get(opts, :name, nil)
    rdms = Keyword.get(opts, :rdms, 5_000)
    deps = Keyword.get(opts, :deps, [])
    log = Keyword.get(opts, :log)

    Setter.check(:name, name, :binary?)
    Setter.check(:rdms, rdms, {:integer, 0, 65_535})
    Setter.check(:deps, deps, {:list?, nil, :binary})

    context = %{
      id: id,
      log: log,
      name: name,
      deps: deps,
      entity: entity,
      module: module,
      stamp: Utils.stamp()
    }

    task = async(context, "super", fn -> setup(rdms, context) end)
    Map.put(context, :task, task)
  end

  def kill(context = %{task: task}) do
    Utils.kill(task)
    task = async(context, "clean", fn -> call(:clean, context) end)
    Utils.await(task)
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

  defp async(%{module: module, id: id, name: name}, role, fun) do
    stamp = Utils.stamp()
    module = Log.inspect?(module)
    Async.spawn("#{stamp}:#{module}:#{id}:#{name}:#{role}", fun)
  end

  # forced kill to trigger managed resources cleanup
  # fixme: no stacktrace in logs to force improvement of error descriptions
  defp call(call, context = %{module: module, entity: entity, deps: deps}) do
    # replace log with parents only if not defined
    Async.ctx(Map.put(context, :log, context.log || Async.ctx()[:log]))

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
      ctx = Map.take(context, [:id, :name])
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
    pids = Enum.map(deps, &Utils.whereis/1)
    async(context, "deps", fn -> monitor(pids) end)
  end

  defp monitor(pids) do
    Enum.each(pids, &Process.monitor/1)
    Utils.receive()
    exit(:kill)
  end

  defp register(_, nil), do: :nop
  defp register(:clean, _), do: :nop
  defp register(:start, name), do: Udb.register!({:entity, name}, nil)
end
