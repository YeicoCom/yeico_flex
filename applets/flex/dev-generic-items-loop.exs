use Terminal

post_log = fn id, error?, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:generic-items:log", %{id: id, dt: dt, error?: error?, msg: msg})
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

publish_items = fn db ->
  items = db.select.([]) |> Enum.to_list()
  Api.putcast!("flex:generic-items:items", items)
  items
end

master_loop = fn state = %{db: db, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:generic-items:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      db.put.(id, params)
      publish_items.(db)
      log_event.(id, false, "Created")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:generic-items:update", _, {id, params}} ->
      db.put.(id, params)
      publish_items.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Updated")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:generic-items:delete", _, id} ->
      db.delete.(id)
      publish_items.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:generic-items:log", _, log} ->
      logs = replace_log.(logs, log)
      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:generic-items:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{db: db} ->
  Bus.subscribe!("flex:generic-items:insert", nil)
  Bus.subscribe!("flex:generic-items:update", nil)
  Bus.subscribe!("flex:generic-items:delete", nil)
  Bus.subscribe!("flex:generic-items:log", nil)
  items = publish_items.(db)

  runners =
    for {id, item} <- items do
      runner = run_item.(id, item)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:generic-items:logs", %{})
  master_loop.(%{db: db, loop: master_loop, runners: runners, logs: %{}})
end

db = libDatabase.api.("dev-generic-items")
Api.loop(dms, master_setup, %{db: db})

:ok
