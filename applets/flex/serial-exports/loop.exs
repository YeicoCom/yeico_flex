defmodule Flex.SerialExports.Loop do
  use Flex

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

  @log "flex:serial-exports:log"

  defp sudo_cmd(cmd) do
    # sudo creates two processes
    case Terminal.user() do
      "root" -> cmd
      _ -> "sudo #{cmd}"
    end
  end

  defp check_tty(id, %{tty: tty}) do
    # otherwise tty device gets created by socat under sudo
    case File.lstat(tty) do
      {:ok, stat = %File.Stat{type: :device}} ->
        Log.debug(tty: tty, stat: stat)
        true

      # serial/by-id links are relative
      {:ok, %File.Stat{type: :symlink}} ->
        with {:ok, path} <- File.read_link(tty),
             dir <- Path.dirname(tty),
             path <- Path.expand(path, dir),
             {:ok, stat = %File.Stat{type: :device}} <- File.lstat(path) do
          Log.debug(tty: tty, stat: stat)
          true
        else
          result ->
            Lg.send(@log, id, true, result)
            raise("Invalid #{tty}: #{inspect(result)}")
        end

      # socat creates tty if not found
      # socat wont open tty until connection
      # tty may be removed while waiting for connection
      result = {:ok, %File.Stat{type: :regular}} ->
        cmd = sudo_cmd("rm -f #{tty}")
        System.shell(cmd, stderr_to_stdout: true)
        Lg.send(@log, id, true, result)
        raise("Invalid #{tty}: #{inspect(result)}")

      result ->
        Lg.send(@log, id, true, result)
        raise("Invalid #{tty}: #{inspect(result)}")
    end
  end

  defp build_cmd(%{tty: tty, bauds: bauds, ip: ip, port: port}) do
    case :os.type() do
      {:unix, :linux} ->
        "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},b#{bauds},raw,echo=0"

      {:unix, :darwin} ->
        "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},ispeed=#{bauds},ospeed=#{bauds},clocal=1,nonblock=1,raw,echo=0"
    end
  end

  defp pid_path(pid) do
    # @run has side effects on dev machine reboot
    dir = "/var/run/flex/serial-exports"
    cmd = sudo_cmd("mkdir -p #{dir}")
    System.shell(cmd, stderr_to_stdout: true)
    "#{dir}/#{pid}"
  end

  defp kill_pid(path, pid) do
    # using -9 prevents sudo from cascading the kill to socat
    cmd = sudo_cmd("kill #{pid}")
    System.shell(cmd, stderr_to_stdout: true)
    cmd = sudo_cmd("rm -fr #{path}")
    System.shell(cmd, stderr_to_stdout: true)
  end

  defp run_cmd(%{tty: tty}, id, cmd) do
    Log.trace(tty: tty, cmd: cmd)
    port = Port.open({:spawn, cmd}, [:binary, :line, :stderr_to_stdout])
    Log.trace(tty: tty, cmd: cmd, port: port)
    _ref = Port.monitor(port)
    {:os_pid, pid} = Port.info(port, :os_pid)
    Log.debug(tty: tty, cmd: cmd, port: port, pid: pid)
    path = pid_path(pid)
    cmd = sudo_cmd("echo '#{id}' > #{path}")
    System.shell(cmd, stderr_to_stdout: true)

    Api.defer(fn ->
      kill_pid(path, pid)
      Log.trace(tty: tty, cmd: cmd)
      # Port.close(port) argument error
    end)

    port
  end

  defp runner_loop(state = %{port: port, id: id, item: %{tty: tty}}) do
    receive do
      # both :eol and :noeol treated as full line
      {^port, {:data, {type, data}}} ->
        Log.trace(tty: tty, type: type, data: data)
        Lg.send(@log, id, true, data)
        runner_loop(state)

      {^port, {:data, data}} ->
        Log.trace(tty: tty, data: data)
        Lg.send(@log, id, true, data)
        runner_loop(state)

      unexpected ->
        Lg.send(@log, id, false, "Closed")
        Log.warn(tty: tty, unexpected: unexpected)
    end
  end

  defp runner_setup(%{id: id, item: item}) do
    # avoid duplicated socat on same tty
    # this does not allow immediate reconnection
    for path <- pid_path("*") |> Path.wildcard() do
      if id == File.read!(path) |> String.trim() do
        pid = Path.basename(path)
        kill_pid(path, pid)
      end
    end

    # this wont be seen because of immediate enoent error
    Lg.send(@log, id, nil, "Starting")
    check_tty(id, item)
    cmd = build_cmd(item)
    cmd = sudo_cmd(cmd)
    port = run_cmd(item, id, cmd)
    Lg.send(@log, id, nil, "Started")
    runner_loop(%{id: id, item: item, cmd: cmd, port: port})
  end

  defp run_enabled(id, item) do
    case item.status do
      :enabled -> Api.loop(2_000, &runner_setup/1, %{id: id, item: item})
      _ -> nil
    end
  end

  defp run_item(id, item) do
    task = run_enabled(id, item)
    %{item: item, task: task}
  end

  defp publish_items(idb) do
    items = Db.select(idb, []) |> Enum.to_list()
    Api.putcast!("flex:serial-exports:items", items)
    items
  end

  defp master_loop(state = %{idb: idb, runners: runners, logs: logs}) do
    receive do
      {"flex:serial-exports:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        publish_items(idb)
        Lg.send(@log, id, false, "Created")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:serial-exports:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Updated")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:serial-exports:delete", _, id} ->
        Db.delete(idb, id)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:serial-exports:log", _, log} ->
        logs = Lg.replace(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:serial-exports:logs", logs)
        state = Map.put(state, :logs, logs)
        master_loop(state)

      {:DOWN, _, :process, _, :killed} ->
        master_loop(state)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  def setup(opts) do
    idb = Keyword.fetch!(opts, :idb)

    for path <- pid_path("*") |> Path.wildcard() do
      pid = Path.basename(path)
      kill_pid(path, pid)
    end

    Bus.subscribe!("flex:serial-exports:insert", nil)
    Bus.subscribe!("flex:serial-exports:update", nil)
    Bus.subscribe!("flex:serial-exports:delete", nil)
    Bus.subscribe!("flex:serial-exports:log", nil)
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item)
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:serial-exports:logs", %{})
    master_loop(%{idb: idb, runners: runners, logs: %{}})
  end
end

:ok
