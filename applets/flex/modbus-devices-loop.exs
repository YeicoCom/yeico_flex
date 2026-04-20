use Terminal

# Arguments
#
# path: to cubdb folder
#

dms = 1_000

post_log = fn id, level, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:modbus:log", %{id: id, dt: dt, level: level, msg: msg})
end

log_event = fn
  id, level, msg when is_binary(msg) -> post_log.(id, level, msg)
  id, level, {:error, msg} when is_binary(msg) -> post_log.(id, level, msg)
  id, level, {:error, msg} -> post_log.(id, level, inspect(msg))
  id, level, msg -> post_log.(id, level, inspect(msg))
end

runner_loop = fn state = %{loop: loop, conn: _conn, id: _id, device: %{name: _name}} ->
  Api.sleep(1000)
  loop.(state)
end

runner_setup = fn %{id: id, device: device = %{ip: ip, port: port, proto: proto}} ->
  with {:ok, conn} <- lib.open.(ip, port, proto) do
    log_event.(id, :trace, "Started")
    runner_loop.(%{id: id, device: device, loop: runner_loop, conn: conn})
  else
    {:error, error} -> log_event.(id, :error, error)
  end
end

publish_devices = fn cubdb ->
  devices = CubDB.select(cubdb, []) |> Enum.to_list()
  Api.putcast!("flex:modbus:devices", devices)
  devices
end

run_enabled = fn id, device ->
  case device.status do
    :enabled -> Api.loop(dms, runner_setup, %{id: id, device: device})
    _ -> nil
  end
end

run_device = fn id, device ->
  task = run_enabled.(id, device)
  %{device: device, task: task}
end

replace_log = fn logs, log = %{id: id, level: level} ->
  case {level, logs[id][:level]} do
    {:trace?, :error} -> logs
    {_, _} -> Map.put(logs, id, Map.drop(log, [:id]))
  end
end

master_loop = fn state = %{cubdb: cubdb, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:modbus:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      CubDB.put(cubdb, id, params)
      publish_devices.(cubdb)
      log_event.(id, :trace, "Created")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus:update", _, {id, params}} ->
      CubDB.put(cubdb, id, params)
      publish_devices.(cubdb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, :trace, "Updated")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus:delete", _, id} ->
      CubDB.delete(cubdb, id)
      publish_devices.(cubdb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, :trace, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus:log", _, log} ->
      logs = replace_log.(logs, log)
      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:modbus:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{cubdb: cubdb} ->
  Bus.subscribe!("flex:modbus:insert", nil)
  Bus.subscribe!("flex:modbus:update", nil)
  Bus.subscribe!("flex:modbus:delete", nil)
  Bus.subscribe!("flex:modbus:log", nil)
  devices = publish_devices.(cubdb)

  runners =
    for {id, device} <- devices do
      runner = run_device.(id, device)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:modbus:logs", %{})
  master_loop.(%{cubdb: cubdb, loop: master_loop, runners: runners, logs: %{}})
end

{:ok, cubdb} = CubDB.start_link(data_dir: path)
Api.loop(dms, master_setup, %{cubdb: cubdb})
