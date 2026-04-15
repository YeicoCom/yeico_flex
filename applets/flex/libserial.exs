use Terminal

# Arguments
#
# path: to cudb folder
#
# Requirements
#
# - socat
# - passwordless sudo or dialout user (not needed)
#
# Features
#
# - socat exits when stdio closes (pkill/muontrap not needed)
# - pkill not available in nerves buildroot
# - socat exits when socket client disconnects
# - socat exits when usb serial port removed
# - socat opens tty until socket client connects

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

dms = 1_000

list = fn ->
  (Path.wildcard("/dev/tty.usbserial*") ++
     Path.wildcard("/dev/tty.usbmodem*") ++
     Path.wildcard("/tmp/tty.socat.*") ++
     Path.wildcard("/dev/ttyACM*") ++
     Path.wildcard("/dev/ttyAMA*") ++
     Path.wildcard("/dev/ttyS*") ++
     Path.wildcard("/dev/ttyUSB*") ++
     Path.wildcard("/dev/serial/by-id/*"))
  |> Enum.sort()
end

post_log = fn id, level, msg ->
  dt = NaiveDateTime.utc_now()
  Bus.broadcast!("flex:serial:log", %{id: id, dt: dt, level: level, msg: msg})
end

log = fn
  id, level, msg when is_binary(msg) -> post_log.(id, level, msg)
  id, level, {:error, msg} when is_binary(msg) -> post_log.(id, level, msg)
  id, level, {:error, msg} -> post_log.(id, level, inspect(msg))
  id, level, msg -> post_log.(id, level, inspect(msg))
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
          log.(id, :error, result)
          raise("Invalid #{tty}: #{inspect(result)}")
      end

    # socat creates tty if not found
    # socat wont open tty until connection
    # tty may be removed while waiting for connection
    result = {:ok, %File.Stat{type: :regular}} ->
      cmd = sudo_cmd.("rm -f #{tty}")
      System.shell(cmd, stderr_to_stdout: true)
      log.(id, :error, result)
      raise("Invalid #{tty}: #{inspect(result)}")

    result ->
      log.(id, :error, result)
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

run_cmd = fn %{tty: tty}, cmd ->
  Api.trace(tty: tty, cmd: cmd)
  port = Port.open({:spawn, cmd}, [:binary, :line, :stderr_to_stdout])
  Api.trace(tty: tty, cmd: cmd, port: port)
  _ref = Port.monitor(port)
  {:os_pid, pid} = Port.info(port, :os_pid)
  Api.debug(tty: tty, cmd: cmd, port: port, pid: pid)
  cmd = sudo_cmd.("touch #{pid_path.(pid)}")
  System.shell(cmd, stderr_to_stdout: true)

  Api.defer(fn ->
    # using -9 prevents sudo from cascading the kill to socat
    cmd = sudo_cmd.("kill #{pid}")
    System.shell(cmd, stderr_to_stdout: true)
    Api.trace(tty: tty, cmd: cmd)
    # Port.close(port) argument error
  end)

  port
end

runner_loop = fn state = %{loop: loop, port: port, id: id, export: %{tty: tty}} ->
  receive do
    # both :eol and :noeol treated as full line
    {^port, {:data, {type, data}}} ->
      Api.trace(tty: tty, type: type, data: data)
      log.(id, :error, data)
      loop.(state)

    {^port, {:data, data}} ->
      Api.trace(tty: tty, data: data)
      log.(id, :error, data)
      loop.(state)

    unexpected ->
      log.(id, :trace?, "Closed")
      Api.warn(tty: tty, unexpected: unexpected)
  end
end

runner_setup = fn %{id: id, export: export} ->
  Api.sleep(dms)
  log.(id, :trace, "Started")
  check_tty.(id, export)
  cmd = build_cmd.(export)
  cmd = sudo_cmd.(cmd)
  port = run_cmd.(export, cmd)
  runner_loop.(%{id: id, export: export, loop: runner_loop, cmd: cmd, port: port})
end

publish_exports = fn cubdb ->
  exports = CubDB.select(cubdb, []) |> Enum.to_list()
  Api.putcast!("flex:serial:exports", exports)
  exports
end

run_export = fn id, export ->
  task =
    case export.status do
      :enabled -> Api.loop(dms, runner_setup, %{id: id, export: export})
      _ -> nil
    end

  %{export: export, task: task}
end

master_loop = fn state = %{cubdb: cubdb, loop: loop, runners: runners, logs: logs} ->
  receive do
    {"flex:serial:insert", _, params} ->
      id = UUID.uuid1() |> ShortUUID.encode!()
      CubDB.put(cubdb, id, params)
      publish_exports.(cubdb)
      log.(id, :trace, "Created")
      runner = run_export.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial:update", _, {id, params}} ->
      CubDB.put(cubdb, id, params)
      publish_exports.(cubdb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log.(id, :trace, "Updated")
      runner = run_export.(id, params)
      runners = Map.put(runners, id, runner)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial:delete", _, id} ->
      CubDB.delete(cubdb, id)
      publish_exports.(cubdb)
      task = runners[id][:task]
      if task, do: Api.kill(task)
      log.(id, :trace, "Deleted")
      runners = Map.delete(runners, id)
      state = Map.put(state, :runners, runners)
      loop.(state)

    {"flex:serial:log", _, log = %{id: id, level: level}} ->
      log = Map.drop(log, [:id])

      logs =
        case {level, logs[id][:level]} do
          {:trace?, :error} -> logs
          {_, _} -> Map.put(logs, id, log)
        end

      ids = Map.keys(runners)
      logs = Map.take(logs, ids)
      Api.putcast!("flex:serial:logs", logs)
      state = Map.put(state, :logs, logs)
      loop.(state)

    {:DOWN, _, :process, _, :killed} ->
      loop.(state)

    unexpected ->
      Api.warn(unexpected: unexpected)
  end
end

master_setup = fn %{cubdb: cubdb} ->
  for p <- pid_path.("*") |> Path.wildcard() do
    n = Path.basename(p)
    # using -9 prevents sudo from cascading the kill to socat
    cmd = sudo_cmd.("kill #{n}")
    System.shell(cmd, stderr_to_stdout: true)
    cmd = sudo_cmd.("rm -fr #{p}")
    System.shell(cmd, stderr_to_stdout: true)
  end

  Bus.subscribe!("flex:serial:insert", nil)
  Bus.subscribe!("flex:serial:update", nil)
  Bus.subscribe!("flex:serial:delete", nil)
  Bus.subscribe!("flex:serial:log", nil)
  exports = publish_exports.(cubdb)

  runners =
    for {id, export} <- exports do
      runner = run_export.(id, export)
      {id, runner}
    end

  runners = Enum.into(runners, %{})
  Api.putcast!("flex:serial:logs", %{})
  master_loop.(%{cubdb: cubdb, loop: master_loop, runners: runners, logs: %{}})
end

{:ok, cubdb} = CubDB.start_link(data_dir: path)
Api.loop(dms, master_setup, %{cubdb: cubdb})

fn
  :list -> list.()
end
