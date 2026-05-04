use Terminal

post_log = fn id, error?, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:modbus-devices:log", %{id: id, dt: dt, error?: error?, msg: msg})
end

log_event = fn
  id, error?, msg when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} -> post_log.(id, error?, inspect(msg))
  id, error?, msg -> post_log.(id, error?, inspect(msg))
end

runner_loop = fn state = %{loop: loop, conn: conn, rts: rts, device: device} ->
  Api.sleep(device.delay)

  conn =
    for pi <- 0..(rts.count - 1)//1, reduce: conn do
      conn ->
        %{pointer: pointer, accessors: accessors} = rts[pi]
        {cmd, decode} = pointer.()

        case mb.api.(:master, exec: {conn, cmd, []}) do
          {:ok, conn} ->
            conn

          {:ok, conn, values} ->
            pairs = Enum.zip(decode.(values), accessors)
            for {value, %{put: put}} <- pairs, do: put.(value)
            conn

          {:error, _conn, error} ->
            throw(device: device, error: error)
        end
    end

  state = Map.put(state, :conn, conn)
  loop.(state)
end

calc_runtimes = fn %{points: points} ->
  for {point, pi} <- Enum.with_index(points), reduce: %{count: length(points)} do
    rts ->
      accessors = plib.accessors.(point)
      %{type: type, slave: slave, address: address, encoding: encoding} = point
      %{encode: encode, decode: decode, factor: factor} = mb.api.(:encoder, get: encoding)
      count = length(points)

      pointer =
        case({type, encoding}) do
          {"RDI", _} ->
            fn -> {{:ri, slave, address, count}, & &1} end

          {"RDO", _} ->
            fn -> {{:rc, slave, address, count}, & &1} end

          {"WDO", _} ->
            fn ->
              values = for %{key: key, get: get} <- accessors, do: {key, get.()}
              {{:fc, slave, address, Keyword.values(values)}, & &1}
            end

          {"RRI", _} ->
            fn -> {{:rir, slave, address, factor * count}, decode} end

          {"RRO", _} ->
            fn -> {{:rhr, slave, address, factor * count}, decode} end

          {"WRO", _} ->
            fn ->
              values = for %{key: key, get: get} <- accessors, do: {key, get.()}
              {{:phr, slave, address, encode.(Keyword.values(values))}, & &1}
            end
        end

      Map.put(rts, pi, %{count: count, accessors: accessors, pointer: pointer})
  end
end

runner_setup = fn %{id: id, device: device = %{ip: ip, port: port, proto: proto}} ->
  proto = mb.api.(:proto, get: proto)
  rts = calc_runtimes.(device)

  with {:ok, conn} <- mb.api.(:master, open: [ip: ip, port: port, proto: proto]) do
    # nil to reset
    log_event.(id, nil, "Started")
    if length(device.points) == 0, do: Api.sleep()
    runner_loop.(%{id: id, rts: rts, device: device, loop: runner_loop, conn: conn})
  else
    {:error, error} -> log_event.(id, true, error)
  end
end

publish_devices = fn db ->
  devices = db.select.([]) |> Enum.sort_by(fn {_, v} -> v.name end)
  Api.putcast!("flex:modbus-devices:items", devices)
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

replace_log = fn logs, log = %{id: id, error?: error?} ->
  case {error?, logs[id][:error?]} do
    {false, true} -> logs
    {_, _} -> Map.put(logs, id, Map.drop(log, [:id]))
  end
end

master_loop = fn state = %{db: db, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:modbus-devices:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      db.put.(id, params)
      publish_devices.(db)
      log_event.(id, false, "Created")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus-devices:update", _, {id, params}} ->
      db.put.(id, params)
      publish_devices.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Updated")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus-devices:delete", _, id} ->
      db.delete.(id)
      publish_devices.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus-devices:log", _, log} ->
      logs = replace_log.(logs, log)
      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:modbus-devices:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{db: db} ->
  Bus.subscribe!("flex:modbus-devices:insert", nil)
  Bus.subscribe!("flex:modbus-devices:update", nil)
  Bus.subscribe!("flex:modbus-devices:delete", nil)
  Bus.subscribe!("flex:modbus-devices:log", nil)
  devices = publish_devices.(db)

  runners =
    for {id, device} <- devices do
      runner = run_device.(id, device)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:modbus-devices:logs", %{})
  master_loop.(%{db: db, loop: master_loop, runners: runners, logs: %{}})
end

Api.loop(dms, master_setup, %{db: db})

:ok
