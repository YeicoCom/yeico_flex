defmodule Flex.ModbusDevices.Loop do
  alias Flex.ModbusDevices.IUtils
  alias Flex.ModbusDevices.PUtils
  use Flex.Use

  @log "flex:modbus-devices:log"

  defp put_status(%{name: name}, status) do
    key = "source:status:#{name}"

    case status do
      "disabled" -> Points.put_value(key, 0)
      "starting" -> Points.put_value(key, 1)
      "started" -> Points.put_value(key, 2)
      "error" -> Points.put_value(key, 3)
    end
  end

  defp runner_loop(state = %{conn: conn, rts: rts, item: item}) do
    Api.sleep(item.delay)

    conn =
      for pi <- 0..(rts.count - 1)//1, reduce: conn do
        conn ->
          %{pointer: pointer, accessors: accessors} = rts[pi]
          {cmd, decode} = pointer.()

          # opts = [tracer: fn d, l -> Api.debug(dir: d, line: Base.encode16(l)) end]
          opts = []

          case Modbus.master_exec(conn, cmd, opts) do
            {:ok, conn} ->
              conn

            {:ok, conn, values} ->
              pairs = Enum.zip(decode.(values), accessors)
              for {value, %{put: put}} <- pairs, do: put.(value)
              conn

            {:error, _conn, error} ->
              throw(item: item, error: error)
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
        %{encode: encode, decode: decode, factor: factor} = Modbus.get_encoder(encoding)
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

  defp runner_setup(%{id: id, item: item = %{ip: ip, port: port, proto: proto}}) do
    proto = Modbus.get_proto(proto)
    rts = calc_runtimes(item)

    put_status(item, "starting")
    Logs.send(@log, id, nil, "Starting")

    with {:ok, conn} <- Modbus.master_open(ip: ip, port: port, proto: proto) do
      Logs.send(@log, id, nil, "Started")
      put_status(item, "started")
      if length(item.points) == 0, do: Api.sleep()

      run = fn ->
        runner_loop(%{id: id, rts: rts, item: item, conn: conn})
      end

      with {:error, _error} <- Api.safe(run) do
        Logs.send(@log, id, true, "Command error")
        put_status(item, "error")
      end
    else
      {:error, _error} ->
        Logs.send(@log, id, true, "Connect error")
        put_status(item, "error")
    end
  end

  defp publish_items(idb) do
    items = Db.select(idb, []) |> Enum.sort_by(fn {_, v} -> v.name end)
    items = Enum.map(items, fn {id, item} -> {id, IUtils.merge(item)} end)
    Api.putcast!("flex:modbus-devices:items", items)
    items
  end

  defp run_enabled(id, item) do
    tag = "modbusdevices:#{id}:#{item.name}"

    case item.status do
      :enabled ->
        Api.loop(tag, 4_000, &runner_setup/1, %{id: id, item: item})

      _ ->
        put_status(item, "disabled")
        nil
    end
  end

  defp run_item(id, item) do
    task = run_enabled(id, item)
    %{item: item, task: task}
  end

  defp master_loop(state = %{idb: idb, runners: runners, logs: logs}) do
    receive do
      {"flex:modbus-devices:insert", _, params} ->
        id = UUID.uuid1() |> ShortUUID.encode!()
        Db.put(idb, id, params)
        publish_items(idb)
        Logs.send(@log, id, false, "Created")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:update", _, {id, params}} ->
        Db.put(idb, id, params)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Updated")
        runner = run_item(id, params)
        runners = Map.put(runners, id, runner)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:delete", _, id} ->
        Db.delete(idb, id)
        publish_items(idb)
        task = runners[id][:task]
        if task, do: Api.kill(task)
        Logs.send(@log, id, false, "Deleted")
        runners = Map.delete(runners, id)
        state = Map.put(state, :runners, runners)
        master_loop(state)

      {"flex:modbus-devices:log", _, log} ->
        logs = Logs.append(logs, log)
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
    items = publish_items(idb)

    runners =
      for {id, item} <- items do
        runner = run_item(id, item)
        {id, runner}
      end

    runners = Enum.into(runners, %{})
    Api.putcast!("flex:modbus-devices:logs", %{})
    master_loop(%{idb: idb, runners: runners, logs: %{}})
  end
end
