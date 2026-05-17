defmodule Flex.UserFiles.Loop do
  use Flex

  @log "flex:user-files:log"

  defp runner_setup(%{id: id}) do
    Bus.subscribe!("flex:user-files:reload:#{id}", nil)
    Api.receive()
    [reload: id]
  end

  defp run_enabled(id, item) do
    tag = "userfiles:#{id}:#{item.name}"

    case item.status do
      :enabled -> Api.loop(tag, 0, &runner_setup/1, %{id: id, item: item})
      _ -> nil
    end
  end

  defp run_item(id, item) do
    task = run_enabled(id, item)
    %{item: item, task: task}
  end

  defp publish_items(idb) do
    items = Db.select(idb, []) |> Enum.sort_by(fn {_, v} -> v.name end)
    Api.putcast!("flex:user-files:items", items)
    for {id, item} <- items, do: Api.putcast!("flex:user-files:item:#{id}", item)
    items
  end

  defp master_loop(state = %{idb: idb, runners: runners, logs: logs}) do
    receive do
      {"flex:user-files:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        publish_items(idb)
        Lg.send(@log, id, false, "Created")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-files:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Updated")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-files:delete", _, id} ->
        Db.delete(idb, id)
        Api.putcast!("flex:user-files:item:#{id}", nil)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-files:log", _, log} ->
        logs = Lg.replace(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:user-files:logs", logs)
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

    Bus.subscribe!("flex:user-files:insert", nil)
    Bus.subscribe!("flex:user-files:update", nil)
    Bus.subscribe!("flex:user-files:delete", nil)
    Bus.subscribe!("flex:user-files:log", nil)
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item)
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:user-files:logs", %{})
    master_loop(%{idb: idb, runners: runners, logs: %{}})
  end
end

:ok
