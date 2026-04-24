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

runner_loop =
  fn state = %{loop: loop, conn: conn, id: id, device: device = %{delay: delay, points: points}} ->
    Api.sleep(delay)

    {conn, result} =
      for {point, pi} <- Enum.with_index(points), reduce: {conn, %{}} do
        {conn, result} ->
          meta = device.meta[pi]

          %{rf: rf, set: set, get: get} = plib.encoder.(point.encoding)

          {cmd, result, get} =
            case {point.type, point.encoding} do
              {"RDI", _} ->
                {{:ri, point.slave, point.address, meta.length}, result, & &1}

              {"RDO", _} ->
                {{:rc, point.slave, point.address, meta.length}, result, & &1}

              {"WDO", _} ->
                values = for %{key: key} <- meta.points, do: {key, plib.get.(key)}
                result = Enum.into(values, result)
                {{:fc, point.slave, point.address, Keyword.values(values)}, result, & &1}

              {"RRI", _} ->
                {{:rir, point.slave, point.address, rf * meta.length}, result, get}

              {"RRO", _} ->
                {{:rhr, point.slave, point.address, rf * meta.length}, result, get}

              {"WRO", _} ->
                values = for %{key: key} <- meta.points, do: {key, plib.get.(key)}
                result = Enum.into(values, result)
                {{:phr, point.slave, point.address, set.(Keyword.values(values))}, result, & &1}
            end

          case dlib.exec.(conn, cmd, []) do
            {:ok, conn} ->
              {conn, result}

            {:ok, conn, values} ->
              {_, _, captures} =
                for _ <- meta.points, reduce: {meta.points, get.(values), []} do
                  {[%{key: key} | points], [value | values], captures} ->
                    plib.put.(key, value)
                    {points, values, [{key, value} | captures]}
                end

              result = Enum.into(captures, result)
              {conn, result}

            {:error, _conn, error} ->
              throw(device: Map.drop(device, [:points]), error: error)
          end
      end

    Bus.broadcast!("flex:modbus-devices:points", {id, result})
    state = Map.put(state, :conn, conn)
    loop.(state)
  end

runner_setup = fn %{id: id, device: device = %{ip: ip, port: port, proto: proto}} ->
  with {:ok, conn} <- dlib.open.(ip, port, proto) do
    # nil to reset
    log_event.(id, nil, "Started")
    if length(device.points) == 0, do: Api.sleep()
    runner_loop.(%{id: id, device: device, loop: runner_loop, conn: conn})
  else
    {:error, error} -> log_event.(id, true, error)
  end
end

complement_device = fn {id, device = %{points: points}} ->
  device = Map.put(device, :meta, %{})

  device =
    for {point, pi} <- Enum.with_index(points), reduce: device do
      device ->
        names = plib.names.(point.names)
        keys = for name <- names, do: plib.key.(point.type, point.encoding, name)
        points = for {name, key} <- Enum.zip(names, keys), do: %{name: name, key: key}
        put_in(device, [:meta, pi], %{length: length(points), points: points})
    end

  {id, device}
end

publish_devices = fn cubdb ->
  devices = CubDB.select(cubdb, []) |> Enum.to_list()
  devices = Enum.map(devices, complement_device)
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
  {id, device} = complement_device.({id, device})
  task = run_enabled.(id, device)
  %{device: device, task: task}
end

replace_log = fn logs, log = %{id: id, error?: error?} ->
  case {error?, logs[id][:error?]} do
    {false, true} -> logs
    {_, _} -> Map.put(logs, id, Map.drop(log, [:id]))
  end
end

master_loop = fn state = %{cubdb: cubdb, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:modbus-devices:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      CubDB.put(cubdb, id, params)
      publish_devices.(cubdb)
      log_event.(id, false, "Created")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus-devices:update", _, {id, params}} ->
      params = Map.drop(params, [:meta])
      CubDB.put(cubdb, id, params)
      publish_devices.(cubdb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Updated")
      runner = run_device.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:modbus-devices:delete", _, id} ->
      CubDB.delete(cubdb, id)
      publish_devices.(cubdb)
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

master_setup = fn %{cubdb: cubdb} ->
  Bus.subscribe!("flex:modbus-devices:insert", nil)
  Bus.subscribe!("flex:modbus-devices:update", nil)
  Bus.subscribe!("flex:modbus-devices:delete", nil)
  Bus.subscribe!("flex:modbus-devices:log", nil)
  devices = publish_devices.(cubdb)

  runners =
    for {id, device} <- devices do
      runner = run_device.(id, device)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:modbus-devices:logs", %{})
  master_loop.(%{cubdb: cubdb, loop: master_loop, runners: runners, logs: %{}})
end

{:ok, cubdb} = CubDB.start_link(data_dir: path)
Api.loop(dms, master_setup, %{cubdb: cubdb})
