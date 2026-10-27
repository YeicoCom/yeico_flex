defmodule Flex.ModbusDevice do
  use Flex.Service
  use Terminal

  @types ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"]
  @encodings ["NONE", "U16BE", "U16LE", "S16BE", "S16LE", "F32BE", "F32LE"]

  defp specs(),
    do: %{
      name: %{initial: nil, check: :binary},
      ip: %{initial: "127.0.0.1", check: :binary},
      port: %{initial: 0, check: {:integer, 0, 65_535}},
      proto: %{initial: "TCP", check: {:in, ["TCP", "RTU"]}},
      delay: %{initial: 0, check: {:integer, 0, nil}},
      points: %{initial: [], check: {:list, nil, &check/2}}
    }

  def add(config = %{points: points}, point) do
    index = length(points)
    Flex.Check.check("points[#{index}]", point, &check/2)
    points = [points, point] |> List.flatten()
    Map.put(config, :points, points)
  end

  defp check(path, value) do
    Flex.Check.check(path, value, :map)
    Flex.Check.check("#{path}.type", value[:type], {:in, @types})
    Flex.Check.check("#{path}.slave", value[:slave], {:integer, 0, 255})
    Flex.Check.check("#{path}.address", value[:address], {:integer, 0, 65_535})
    Flex.Check.check("#{path}.encoding", value[:encoding], {:in, @encodings})
    Flex.Check.check("#{path}.names", value[:names], :binary)
    length = value[:names] |> String.trim() |> String.length()
    Flex.Check.check("#{path}.names.length", length, {:integer, 1, nil})
  end

  defp setup(config = %{ip: ip, port: port, proto: proto, points: points, name: name}) do
    sid = Process.get(:__sid__)
    Log.debug("#{sid} run")
    status(name, "starting")
    clean(fn -> status(name, "error") end)
    protom = Modbus.Protocol.by_name(proto)

    with {:ok, conn} <- Modbus.Master.open(ip: ip, port: port, proto: protom) do
      clean(fn -> Modbus.Master.close(conn) end)

      {:error, %{error: error}} =
        Api.safe(fn ->
          # catch point spec errors
          rts = runtimes(config)
          # started status until fully initialized
          status(name, "started")
          if length(points) == 0, do: Api.sleep()
          loop(%{rts: rts, config: config, conn: conn, sid: sid})
        end)

      # Flex.Service.kill "modbus-slave:4031:127.0.0.1:TCP:setup"
      # test with invalid point, proto, or disconnection
      Log.warn("#{sid} #{Api.inspect?(error)}")
    else
      {:error, error} ->
        # test with invalid endpoint
        Log.warn("#{sid} #{Api.inspect?(error)}")
    end
  end

  defp loop(state = %{conn: conn, rts: rts, config: %{delay: delay, name: name}}) do
    Api.sleep(delay)

    conn =
      for pi <- 0..(rts.count - 1)//1, reduce: conn do
        conn ->
          %{pointer: pointer, accessors: accessors} = rts[pi]
          {cmd, decode} = pointer.()

          opts = []
          # opts = [tracer: fn d, l -> Api.trace(dir: d, line: Base.encode16(l)) end]

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
    stamp(name)
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

  defp status(name, status) do
    key = "source:status:#{name}"

    case status do
      # "disabled" -> Flex.Points.put_value(key, 0)
      "starting" -> Flex.Points.put_value(key, 1)
      "started" -> Flex.Points.put_value(key, 2)
      "error" -> Flex.Points.put_value(key, 3)
    end
  end

  defp stamp(name) do
    stamp = NaiveDateTime.utc_now()
    key = "source:stamp:#{name}"
    Flex.Points.put_value(key, stamp)
  end
end
