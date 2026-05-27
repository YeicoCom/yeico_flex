defmodule Flex.UserScreens.Loop do
  alias Flex.UserScreens.IUtils
  alias Flex.UserScreens.View
  use Flex.Use

  @log "flex:user-screens:log"

  defp run_view(_, %{route: ""}, _ctx) do
    :ok
  end

  defp run_view(id, %{route: route}, %{idb: idb, ddb: ddb}) do
    Terminal.view(route, View.handler(path: route, fid: id, idb: idb, ddb: ddb))
  end

  defp runner_setup(%{id: id, item: item, ctx: ctx}) do
    Logs.send(@log, id, nil, "Started")
    run_view(id, item, ctx)
    Api.sleep()
  end

  defp run_enabled(id, item, ctx) do
    tag = "userscreens:#{id}:#{item.name}:#{item.route}"

    case item.status do
      :enabled -> Api.async(tag, &runner_setup/1, %{id: id, item: item, ctx: ctx})
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
    Api.putcast!("flex:user-screens:items", items)
    for {id, item} <- items, do: Api.putcast!("flex:user-screens:item:#{id}", item)
    items
  end

  defp master_loop(state = %{idb: idb, ddb: ddb, runners: runners, logs: logs}) do
    receive do
      {"flex:user-screens:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        publish_items(idb)
        Logs.send(@log, id, false, "Created")
        runner = run_item(id, params, %{idb: idb, ddb: ddb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-screens:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Updated")
        runner = run_item(id, params, %{idb: idb, ddb: ddb})
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-screens:delete", _, id} ->
        Db.delete(idb, id)
        Db.delete(ddb, id)
        Api.putcast!("flex:user-screens:design:#{id}", nil)
        Api.putcast!("flex:user-screens:item:#{id}", nil)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:user-screens:log", _, log} ->
        logs = Logs.replace(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:user-screens:logs", logs)
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
    ddb = Keyword.fetch!(opts, :ddb)

    Bus.subscribe!("flex:user-screens:insert", nil)
    Bus.subscribe!("flex:user-screens:update", nil)
    Bus.subscribe!("flex:user-screens:delete", nil)
    Bus.subscribe!("flex:user-screens:log", nil)
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item, %{idb: idb, ddb: ddb})
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:user-screens:logs", %{})
    master_loop(%{idb: idb, ddb: ddb, runners: runners, logs: %{}})
  end
end

:ok
