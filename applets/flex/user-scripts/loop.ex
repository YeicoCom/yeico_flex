defmodule Flex.UserScripts.Loop do
  alias Flex.UserScripts.IUtils
  use Flex.Use

  @log "flex:user-scripts:log"

  defp run_code({id, code}) do
    api = Process.get(:__api__)

    Process.put(:__api__, fn
      :entry -> id
      :route -> "script"
      other -> api.(other)
    end)

    Log.info("Starting...")
    Api.evals("script", code, [])
    Process.exit(self(), :kill)
  end

  defp runner_setup(%{id: id, item: %{name: name}, ctx: %{cdb: cdb}}) do
    Udb.register!({:script, id}, name)
    code = String.trim(IUtils.load(cdb, id) || "")
    Logs.send(@log, id, false, "Started")
    tag = "userscripts:#{id}:#{name}:run"
    code? = String.length(code) > 0
    if code?, do: Api.defer(fn -> Logs.send(@log, id, false, "Exited") end)
    if code?, do: Api.async(tag, &run_code/1, {id, code})
    Api.receive()
    Process.exit(self(), :kill)
  end

  defp run_loop(id, item, ctx) do
    tag = "userscripts:#{id}:#{item.name}"
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
    Api.putcast!("flex:user-scripts:items", items)
    for {id, item} <- items, do: Api.putcast!("flex:user-scripts:item:#{id}", item)
    items
  end

  defp master_loop(state = %{idb: idb, cdb: cdb, runners: runners, logs: logs}) do
    receive do
      {"flex:user-scripts:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        Db.put(cdb, id, IUtils.template())
        publish_items(idb)
        Logs.send(@log, id, false, "Created")
        runner = run_item(id, params, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Updated")
        runner = run_item(id, params, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:reload", _, id} ->
        # raises on deleted item save from code editor
        %{task: task, item: item} = runners[id]
        if task, do: Api.kill(task)
        runner = run_item(id, item, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:delete", _, id} ->
        Db.delete(cdb, id)
        Db.delete(idb, id)
        Api.putcast!("flex:user-scripts:item:#{id}", nil)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:log", _, log} ->
        logs = Logs.append(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:user-scripts:logs", logs)
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

    Bus.subscribe!("flex:user-scripts:reload", nil)
    Bus.subscribe!("flex:user-scripts:insert", nil)
    Bus.subscribe!("flex:user-scripts:update", nil)
    Bus.subscribe!("flex:user-scripts:delete", nil)
    Bus.subscribe!("flex:user-scripts:log", nil)
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item, %{cdb: cdb})
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:user-scripts:logs", %{})
    master_loop(%{idb: idb, cdb: cdb, runners: runners, logs: %{}})
  end
end
