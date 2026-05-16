defmodule Flex.UserScripts.Loop do
  alias Flex.UserScripts.IUtils
  use Flex

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
    Api.sleep()
  end

  defp runner_setup(%{id: id, item: item, ctx: %{cdb: cdb}}) do
    Bus.subscribe!("flex:user-scripts:reload:#{id}", nil)
    Udb.register!({:script, id}, item.name)
    Mdb.register!(:script, id)
    code = String.trim(IUtils.load(cdb, id) || "")
    Lg.send(@log, id, nil, "Started")
    task = if String.length(code) > 0, do: Api.async(&run_code/1, {id, code})
    Api.receive()
    if task, do: Api.kill(task)
    [reload: id]
  end

  defp run_enabled(id, item, ctx) do
    case item.status do
      :enabled -> Api.loop(0, &runner_setup/1, %{id: id, item: item, ctx: ctx})
      _ -> nil
    end
  end

  defp run_item(id, item, ctx) do
    task = run_enabled(id, item, ctx)
    %{item: item, task: task}
  end

  defp publish_items(idb) do
    items = Db.select(idb, []) |> Enum.sort_by(fn {_, v} -> v.name end)
    Api.putcast!("flex:user-scripts:items", items)
    for {id, item} <- items, do: Api.putcast!("flex:user-scripts:item:#{id}", item)
    items
  end

  defp master_loop(state = %{idb: idb, cdb: cdb, runners: runners, logs: logs}) do
    receive do
      {"flex:user-scripts:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        Db.put(cdb, id, "use Terminal\n\n:ok")
        publish_items(idb)
        Lg.send(@log, id, false, "Created")
        runner = run_item(id, params, %{cdb: cdb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Updated")
        runner = run_item(id, params, %{cdb: cdb})
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
        Lg.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-scripts:log", _, log} ->
        logs = Lg.replace(logs, log)
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

:ok
