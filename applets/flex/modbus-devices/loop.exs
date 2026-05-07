defmodule Flex.ModbusDevices.Loop do
  alias Flex.ModbusDevices.PUtils
  use Flex

  @log "flex:modbus-devices:log"

  defp put_status(%{name: name}, status) do
    key = "source:status:#{name}"

    case status do
      "disabled" -> Pt.put_value(key, 0)
      "starting" -> Pt.put_value(key, 1)
      "started" -> Pt.put_value(key, 2)
      "error" -> Pt.put_value(key, 3)
    end
  end

  defp runner_loop(state = %{conn: conn, rts: rts, device: device}) do
    Api.sleep(device.delay)

    conn =
      for pi <- 0..(rts.count - 1)//1, reduce: conn do
        conn ->
          %{pointer: pointer, accessors: accessors} = rts[pi]
          {cmd, decode} = pointer.()

          case Mb.master_exec(conn, cmd, []) do
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
    runner_loop(state)
  end

  defp calc_runtimes(%{points: points}) do
    for {point, pi} <- Enum.with_index(points), reduce: %{count: length(points)} do
      rts ->
        accessors = PUtils.accessors(point)
        %{type: type, slave: slave, address: address, encoding: encoding} = point
        %{encode: encode, decode: decode, factor: factor} = Mb.get_encoder(encoding)
        count = length(accessors)

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

  defp runner_setup(%{id: id, device: device = %{ip: ip, port: port, proto: proto}}) do
    proto = Mb.get_proto(proto)
    rts = calc_runtimes(device)

    put_status(device, "starting")
    Lg.send(@log, id, nil, "Starting")

    with {:ok, conn} <- Mb.master_open(ip: ip, port: port, proto: proto) do
      Lg.send(@log, id, nil, "Started")
      put_status(device, "started")
      if length(device.points) == 0, do: Api.sleep()

      run = fn ->
        runner_loop(%{id: id, rts: rts, device: device, conn: conn})
      end

      with {:error, error} <- Api.safe(run) do
        Lg.send(@log, id, true, error)
        put_status(device, "error")
      end
    else
      {:error, error} ->
        Lg.send(@log, id, true, error)
        put_status(device, "error")
    end
  end

  defp publish_devices(idb) do
    devices = Db.select(idb, []) |> Enum.sort_by(fn {_, v} -> v.name end)
    Api.putcast!("flex:modbus-devices:items", devices)
    devices
  end

  defp run_enabled(id, device) do
    case device.status do
      :enabled ->
        Api.loop(4_000, &runner_setup/1, %{id: id, device: device})

      _ ->
        put_status(device, "disabled")
        nil
    end
  end

  defp run_device(id, device) do
    task = run_enabled(id, device)
    %{device: device, task: task}
  end

  defp master_loop(state = %{idb: idb, runners: runners, logs: logs}) do
    receive do
      {"flex:modbus-devices:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        publish_devices(idb)
        Lg.send(@log, id, false, "Created")
        runner = run_device(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_devices(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Updated")
        runner = run_device(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:delete", _, id} ->
        Db.delete(idb, id)
        publish_devices(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Lg.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:log", _, log} ->
        logs = Lg.replace(logs, log)
        ids = Map.keys(runners)
        logs = Map.take(logs, ids)
        Api.putcast!("flex:modbus-devices:logs", logs)
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
    Bus.subscribe!("flex:modbus-devices:insert", nil)
    Bus.subscribe!("flex:modbus-devices:update", nil)
    Bus.subscribe!("flex:modbus-devices:delete", nil)
    Bus.subscribe!("flex:modbus-devices:log", nil)
    devices = publish_devices(idb)

    runners =
      for {id, device} <- devices do
        runner = run_device(id, device)
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:modbus-devices:logs", %{})
    master_loop(%{idb: idb, runners: runners, logs: %{}})
  end
end

:ok
