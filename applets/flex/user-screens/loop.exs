use Terminal

post_log = fn id, error?, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:user-screens:log", %{id: id, dt: dt, error?: error?, msg: msg})
end

log_event = fn
  id, error?, msg when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} -> post_log.(id, error?, inspect(msg))
  id, error?, msg -> post_log.(id, error?, inspect(msg))
end

runner_setup = fn %{id: id} ->
  # nil to reset
  log_event.(id, nil, "Started")
  Api.sleep()
end

run_enabled = fn id, item ->
  case item.status do
    :enabled -> Api.loop(dms, runner_setup, %{id: id, item: item})
    _ -> nil
  end
end

run_item = fn id, item ->
  task = run_enabled.(id, item)
  %{item: item, task: task}
end

replace_log = fn logs, log = %{id: id, error?: error?} ->
  case {error?, logs[id][:error?]} do
    {false, true} -> logs
    {_, _} -> Map.put(logs, id, Map.drop(log, [:id]))
  end
end

publish_items = fn idb ->
  items = idb.select.([]) |> Enum.sort_by(fn {_, v} -> v.name end)
  Api.putcast!("flex:user-screens:items", items)
  for {id, item} <- items, do: Api.putcast!("flex:user-screens:item:#{id}", item)
  items
end

master_loop = fn state = %{idb: idb, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:user-screens:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      idb.put.(id, params)
      publish_items.(idb)
      log_event.(id, false, "Created")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:user-screens:update", _, {id, params}} ->
      idb.put.(id, params)
      publish_items.(idb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Updated")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:user-screens:delete", _, id} ->
      idb.delete.(id)
      ddb.delete.(id)
      Api.putcast!("flex:user-screens:design:#{id}", nil)
      Api.putcast!("flex:user-screens:item:#{id}", nil)
      publish_items.(idb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:user-screens:log", _, log} ->
      logs = replace_log.(logs, log)
      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:user-screens:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{idb: idb} ->
  Bus.subscribe!("flex:user-screens:insert", nil)
  Bus.subscribe!("flex:user-screens:update", nil)
  Bus.subscribe!("flex:user-screens:delete", nil)
  Bus.subscribe!("flex:user-screens:log", nil)
  items = publish_items.(idb)

  runners =
    for {id, item} <- items do
      runner = run_item.(id, item)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:user-screens:logs", %{})
  master_loop.(%{idb: idb, loop: master_loop, runners: runners, logs: %{}})
end

Api.loop(dms, master_setup, %{idb: idb})

:ok
