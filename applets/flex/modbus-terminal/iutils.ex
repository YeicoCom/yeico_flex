defmodule Flex.ModbusTerminal.IUtils do
  use Flex.Live

  @protos ["TCP", "RTU"]
  @options %{protos: @protos}
  @title "Modbus Connection"

  def title, do: @title
  def options, do: @options

  def append(socket, state = %{logid: logid, tzoffset: tzoffset}, type, line) do
    line = if is_binary(line), do: line, else: inspect(line)
    line = encode(type, line)
    dt = NaiveDateTime.utc_now()
    log = %{id: logid, dt: dt, style: style(type), line: line}
    log = Lg.shift(tzoffset, log)
    socket = stream(socket, :logs, [log])
    state = Map.update!(state, :logid, &(&1 + 1))
    {socket, state}
  end

  def setup opts do
    ip = Keyword.fetch!(opts, :ip)
    port = Keyword.fetch!(opts, :port)
    proto = Keyword.fetch!(opts, :proto)
    parent = Keyword.fetch!(opts, :parent)

    with {:ok, conn} <- Mb.master_open(ip: ip, port: port, proto: Mb.get_proto(proto)) do
      Api.defer(fn -> Mb.master_close(conn) end)
      send(parent, {:socket, self(), :success, "Connected to #{proto}:#{ip}:#{port}"})

      tracer = fn type, data ->
        send(parent, {:socket, self(), type, data})
        :ok
      end

      loop(conn, %{parent: parent, tracer: tracer})
    else
      {:error, error} ->
        send(parent, {:socket, self(), :error, error: error})
        Log.warn(error: error)
    end
  end

  defp loop(conn, params = %{parent: parent, tracer: tracer}) do
    receive do
      {:exec, %{cmd: cmd, get: get}} ->
        case Mb.master_exec(conn, cmd, tracer: tracer) do
          {:ok, conn} ->
            send(parent, {:socket, self(), :success, :ok})
            loop(conn, params)

          {:ok, conn, values} ->
            send(parent, {:socket, self(), :success, get.(values)})
            loop(conn, params)

          {:error, _conn, error = :closed} ->
            send(parent, {:socket, self(), :error, error})
            Log.warn(error: error)

          {:error, conn, error} ->
            send(parent, {:socket, self(), :error, error})
            loop(conn, params)
        end

      unexpected ->
        send(parent, {:socket, self(), :error, unexpected: unexpected})
        Log.debug(unexpected: unexpected)
    end
  end

  defp style(:trace), do: "text-gray-200"
  defp style(:error), do: "text-red-500"
  defp style(:input), do: "text-blue-500"
  defp style(:output), do: "text-purple-500"
  defp style(:success), do: "text-lime-500"

  defp encode(:input, line), do: Base.encode16(line)
  defp encode(:output, line), do: Base.encode16(line)
  defp encode(_, line), do: line
end

:ok
