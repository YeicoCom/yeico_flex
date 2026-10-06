defmodule Flex3.ModbusDevice do
  @initial %{
    name: nil,
    ip: "127.0.0.1",
    port: 0,
    proto: "TCP",
    delay: 0,
    points: []
  }

  @checks %{
    name: :binary,
    ip: :binary,
    port: {:integer, 0, 65_535},
    proto: {:in, ["TCP", "RTU"]},
    delay: {:integer, 0, nil},
    points: {:list, nil, :any}
  }

  use Flex3.Service
  use Terminal

  defp name(%{port: port, ip: ip, proto: proto, name: name}),
    do: "modbus-device:#{port}:#{ip}:#{proto}:#{name}"

  defp setup(config = %{ip: ip, port: port, proto: proto}) do
    sid = name(config)
    protom = Modbus.Protocol.by_name(proto)
    rts = runtimes(config)
    status(config, "starting")

    with {:ok, conn} <- Modbus.Master.open(ip: ip, port: port, proto: protom) do
      clean(fn -> Modbus.Master.close(conn) end)
      status(config, "started")
      if length(config.points) == 0, do: Api.sleep()
      loop = fn -> loop(%{rts: rts, config: config, conn: conn, sid: sid}) end

      with {:error, error} <- Api.safe(loop) do
        error =
          case error do
            %{error: error} -> error
            error -> error
          end

        Log.warn("#{sid} #{Api.inspect?(error)}")
        status(config, "error")
      end
    else
      {:error, error} ->
        Log.warn("#{sid} #{Api.inspect?(error)}")
        status(config, "error")
    end
  end

  defp loop(state = %{conn: conn, rts: rts, config: config}) do
    Api.sleep(config.delay)

    conn =
      for pi <- 0..(rts.count - 1)//1, reduce: conn do
        conn ->
          %{pointer: pointer, accessors: accessors} = rts[pi]
          {cmd, decode} = pointer.()

          opts = []
          # opts = [tracer: fn d, l -> Api.debug(dir: d, line: Base.encode16(l)) end]

          case Modbus.Master.exec(conn, cmd, opts) do
            {:ok, conn} ->
              conn

            {:ok, conn, values} ->
              pairs = Enum.zip(decode.(values), accessors)
              for {value, %{put: put}} <- pairs, do: put.(value)
              conn

            {:error, _conn, error} ->
              throw(error)
          end
      end

    state = Map.put(state, :conn, conn)
    loop(state)
  end

  defp runtimes(%{points: points}) do
    for {point, pi} <- Enum.with_index(points), reduce: %{count: length(points)} do
      rts ->
        accessors = Modbus.Points.accessors(point)
        %{type: type, slave: slave, address: address, encoding: encoding} = point
        %{encode: encode, decode: decode, factor: factor} = Modbus.Encoder.for(encoding)
        count = length(accessors)

        pointer =
          case({type, encoding}) do
            {"RDI", _} ->
              fn -> {{:ri, slave, address, count}, & &1} end

            {"RDO", _} ->
              fn -> {{:rc, slave, address, count}, & &1} end

            {"WDO", _} ->
              fn ->
                values = for %{get: get} <- accessors, do: get.()
                {{:fc, slave, address, values}, & &1}
              end

            {"RRI", _} ->
              fn -> {{:rir, slave, address, factor * count}, decode} end

            {"RRO", _} ->
              fn -> {{:rhr, slave, address, factor * count}, decode} end

            {"WRO", _} ->
              fn ->
                values = for %{get: get} <- accessors, do: get.()
                {{:phr, slave, address, encode.(values)}, & &1}
              end
          end

        Map.put(rts, pi, %{count: count, accessors: accessors, pointer: pointer})
    end
  end

  defp status(%{name: name}, status) do
    key = "source:status:#{name}"

    case status do
      "disabled" -> Flex3.Points.put_value(key, 0)
      "starting" -> Flex3.Points.put_value(key, 1)
      "started" -> Flex3.Points.put_value(key, 2)
      "error" -> Flex3.Points.put_value(key, 3)
    end
  end
end
