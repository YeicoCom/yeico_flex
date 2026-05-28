defmodule Flex.UserBackends.Loop do
  alias Flex.UserBackends.IUtils
  alias Flex.UserBackends.Runner
  use Flex.Use

  @log "flex:user-backends:log"

  defp run_code({id, name, code}) do
    api = Process.get(:__api__)

    Process.put(:__api__, fn
      :entry -> id
      :route -> "backend"
      other -> api.(other)
    end)

    Log.info("Starting...")
    Runner.run(id, name, code)
    Process.exit(self(), :kill)
  end

  defp runner_setup(%{id: id, item: %{name: name}, ctx: %{cdb: cdb}}) do
    Udb.register!({:backend, id}, name)
    code = String.trim(IUtils.load(cdb, id) || "")
    Logs.send(@log, id, nil, "Started")
    tag = "userbackends:#{id}:#{name}:run"
    code? = String.length(code) > 0
    if code?, do: Api.defer(fn -> Logs.send(@log, id, nil, "Exited") end)
    if code?, do: Api.async(tag, &run_code/1, {id, name, code})
    Api.receive()
    Process.exit(self(), :kill)
  end

  defp run_loop(id, item, ctx) do
    tag = "userbackends:#{id}:#{item.name}"
    Api.loop(tag, item.delay, &runner_setup/1, %{id: id, item: item, ctx: ctx})
  end

  defp run_enabled(id, item, ctx) do
    case item.status do
      :enabled -> run_loop(id, item, ctx)
      _ -> nil
    end
  end

  defp run_item(id, item, ctx) do
    task = run_enabled(id, item, ctx)
    %{item: item, task: task}
  end

  defp publish_items(idb) do
    items = Db.select(idb, []) |> Enum.sort_by(fn {_, v} -> v.name end)
    items = Enum.map(items, fn {id, item} -> {id, IUtils.merge(item)} end)
    Api.putcast!("flex:user-backends:items", items)
    for {id, item} <- items, do: Api.putcast!("flex:user-backends:item:#{id}", item)
    items
  end

  defp master_loop(state = %{idb: idb, cdb: cdb, runners: runners, logs: logs}) do
    receive do
      {"flex:user-backends:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        Db.put(cdb, id, IUtils.template())
        publish_items(idb)
        Logs.send(@log, id, false, "Created")
        runner = run_item(id, params, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-backends:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Updated")
        runner = run_item(id, params, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-backends:delete", _, id} ->
        Db.delete(cdb, id)
        Db.delete(idb, id)
        Api.putcast!("flex:user-backends:item:#{id}", nil)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Deleted")
        Runner.clean(id)
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-backends:reload", _, id} ->
        # raises on deleted item save from code editor
        %{task: task, item: item} = runners[id]
        if task, do: Api.kill(task)
        runner = run_item(id, item, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-backends:log", _, log} ->
        logs = Logs.replace(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:user-backends:logs", logs)
        state = Map.put(state, :logs, logs)
        master_loop(state)

      {:DOWN, _, :process, _, :killed} ->
        master_loop(state)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  def setup opts do
    idb = Keyword.fetch!(opts, :idb)
    cdb = Keyword.fetch!(opts, :cdb)

    Bus.subscribe!("flex:user-backends:reload", nil)
    Bus.subscribe!("flex:user-backends:insert", nil)
    Bus.subscribe!("flex:user-backends:update", nil)
    Bus.subscribe!("flex:user-backends:delete", nil)
    Bus.subscribe!("flex:user-backends:log", nil)
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item, %{cdb: cdb})
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:user-backends:logs", %{})
    master_loop(%{idb: idb, cdb: cdb, runners: runners, logs: %{}})
  end
end
