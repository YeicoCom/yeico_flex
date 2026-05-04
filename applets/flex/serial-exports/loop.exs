use Terminal

# /dev/tty.usbserial FTDI usb serial adapter on macos
# /dev/tty.usbmodem Honeywell Voyager XP 1472G Lector de Código de Barras Omnidireccional 1D/2D
# /dev/ttyACM cm4 serial ports seeed cm4 edgebox rpi 200
# /dev/ttyAMA cm4 serial ports waveshare cm4 io wireless base
# /tmp/tty.socat
#   sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B
#   sudo socat -d pty,link=/tmp/tty.socat.L TCP4-LISTEN:8001
#   sudo socat -d pty,link=/tmp/tty.socat.C TCP4:localhost:8001
#   nc -l 8001
#   nc localhost 8001

post_log = fn id, error?, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:serial-exports:log", %{id: id, dt: dt, error?: error?, msg: msg})
end

log_event = fn
  id, error?, msg when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} when is_binary(msg) -> post_log.(id, error?, msg)
  id, error?, {:error, msg} -> post_log.(id, error?, inspect(msg))
  id, error?, msg -> post_log.(id, error?, inspect(msg))
end

sudo_cmd = fn cmd ->
  # sudo creates two processes
  case Terminal.user() do
    "root" -> cmd
    _ -> "sudo #{cmd}"
  end
end

check_tty = fn id, %{tty: tty} ->
  # otherwise tty device gets created by socat under sudo
  case File.lstat(tty) do
    {:ok, stat = %File.Stat{type: :device}} ->
      Api.debug(tty: tty, stat: stat)
      true

    # serial/by-id links are relative
    {:ok, %File.Stat{type: :symlink}} ->
      with {:ok, path} <- File.read_link(tty),
           dir <- Path.dirname(tty),
           path <- Path.expand(path, dir),
           {:ok, stat = %File.Stat{type: :device}} <- File.lstat(path) do
        Api.debug(tty: tty, stat: stat)
        true
      else
        result ->
          log_event.(id, true, result)
          raise("Invalid #{tty}: #{inspect(result)}")
      end

    # socat creates tty if not found
    # socat wont open tty until connection
    # tty may be removed while waiting for connection
    result = {:ok, %File.Stat{type: :regular}} ->
      cmd = sudo_cmd.("rm -f #{tty}")
      System.shell(cmd, stderr_to_stdout: true)
      log_event.(id, true, result)
      raise("Invalid #{tty}: #{inspect(result)}")

    result ->
      log_event.(id, true, result)
      raise("Invalid #{tty}: #{inspect(result)}")
  end
end

build_cmd = fn %{tty: tty, bauds: bauds, ip: ip, port: port} ->
  case :os.type() do
    {:unix, :linux} ->
      "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},b#{bauds},raw,echo=0"

    {:unix, :darwin} ->
      "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},ispeed=#{bauds},ospeed=#{bauds},clocal=1,nonblock=1,raw,echo=0"
  end
end

pid_path = fn pid ->
  # @run has side effects on dev machine reboot
  dir = "/var/run/flex/serial-exports"
  cmd = sudo_cmd.("mkdir -p #{dir}")
  System.shell(cmd, stderr_to_stdout: true)
  "#{dir}/#{pid}"
end

kill_pid = fn path, pid ->
  # using -9 prevents sudo from cascading the kill to socat
  cmd = sudo_cmd.("kill #{pid}")
  System.shell(cmd, stderr_to_stdout: true)
  cmd = sudo_cmd.("rm -fr #{path}")
  System.shell(cmd, stderr_to_stdout: true)
end

run_cmd = fn %{tty: tty}, id, cmd ->
  Api.trace(tty: tty, cmd: cmd)
  port = Port.open({:spawn, cmd}, [:binary, :line, :stderr_to_stdout])
  Api.trace(tty: tty, cmd: cmd, port: port)
  _ref = Port.monitor(port)
  {:os_pid, pid} = Port.info(port, :os_pid)
  Api.debug(tty: tty, cmd: cmd, port: port, pid: pid)
  path = pid_path.(pid)
  cmd = sudo_cmd.("echo '#{id}' > #{path}")
  System.shell(cmd, stderr_to_stdout: true)

  Api.defer(fn ->
    kill_pid.(path, pid)
    Api.trace(tty: tty, cmd: cmd)
    # Port.close(port) argument error
  end)

  port
end

runner_loop = fn state = %{loop: loop, port: port, id: id, item: %{tty: tty}} ->
  receive do
    # both :eol and :noeol treated as full line
    {^port, {:data, {type, data}}} ->
      Api.trace(tty: tty, type: type, data: data)
      log_event.(id, true, data)
      loop.(state)

    {^port, {:data, data}} ->
      Api.trace(tty: tty, data: data)
      log_event.(id, true, data)
      loop.(state)

    unexpected ->
      log_event.(id, false, "Closed")
      Api.warn(tty: tty, unexpected: unexpected)
  end
end

runner_setup = fn %{id: id, item: item} ->
  # avoid duplicated socat on same tty
  # this does not allow immediate reconnection
  for path <- pid_path.("*") |> Path.wildcard() do
    if id == File.read!(path) |> String.trim() do
      pid = Path.basename(path)
      kill_pid.(path, pid)
    end
  end

  # nil to reset
  log_event.(id, nil, "Started")
  check_tty.(id, item)
  cmd = build_cmd.(item)
  cmd = sudo_cmd.(cmd)
  port = run_cmd.(item, id, cmd)
  runner_loop.(%{id: id, item: item, loop: runner_loop, cmd: cmd, port: port})
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
  Api.putcast!("flex:serial-exports:items", items)
  items
end

master_loop = fn state = %{db: db, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:serial-exports:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      db.put.(id, params)
      publish_items.(db)
      log_event.(id, false, "Created")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial-exports:update", _, {id, params}} ->
      db.put.(id, params)
      publish_items.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Updated")
      runner = run_item.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial-exports:delete", _, id} ->
      db.delete.(id)
      publish_items.(db)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log_event.(id, false, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial-exports:log", _, log} ->
      logs = replace_log.(logs, log)
      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:serial-exports:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{db: db} ->
  for path <- pid_path.("*") |> Path.wildcard() do
    pid = Path.basename(path)
    kill_pid.(path, pid)
  end

  Bus.subscribe!("flex:serial-exports:insert", nil)
  Bus.subscribe!("flex:serial-exports:update", nil)
  Bus.subscribe!("flex:serial-exports:delete", nil)
  Bus.subscribe!("flex:serial-exports:log", nil)
  items = publish_items.(db)

  runners =
    for {id, item} <- items do
      runner = run_item.(id, item)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:serial-exports:logs", %{})
  master_loop.(%{db: db, loop: master_loop, runners: runners, logs: %{}})
end

Api.loop(dms, master_setup, %{db: db})

:ok
