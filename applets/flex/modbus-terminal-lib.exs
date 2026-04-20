use Terminal

protos = ["TCP", "RTU"]
options = %{protos: protos}

toproto = fn
  "TCP" -> modbus.tcp_proto
  "RTU" -> modbus.rtu_proto
end

shift = fn tzoffset, log = %{dt: dt} ->
  dt = NaiveDateTime.shift(dt, hour: tzoffset)
  dt = NaiveDateTime.to_time(dt)
  %{log | dt: dt}
end

loop = fn loop, parent, conn ->
  tracer = fn type, data ->
    send(parent, {:socket, self(), type, data})
    :ok
  end

  receive do
    {:exec, cmd} ->
      case modbus.master.({:exec, conn, cmd, tracer: tracer}) do
        {:ok, conn} ->
          send(parent, {:socket, self(), :success, :ok})
          loop.(loop, parent, conn)

        {:ok, conn, values} ->
          send(parent, {:socket, self(), :success, values: values})
          loop.(loop, parent, conn)

        {:error, _conn, error = :closed} ->
          send(parent, {:socket, self(), :error, error: error})
          Api.warn(error: error)

        {:error, conn, error} ->
          send(parent, {:socket, self(), :error, error: error})
          loop.(loop, parent, conn)
      end

    unexpected ->
      send(parent, {:socket, self(), :error, unexpected: unexpected})
      Api.warn(unexpected: unexpected)
  end
end

setup = fn {parent, %{ip: ip, port: port, proto: proto}} ->
  with {:ok, conn} <- modbus.master.({:open, ip: ip, port: port, proto: toproto.(proto)}) do
    send(parent, {:socket, self(), :success, "Connected to #{proto}:#{ip}:#{port}"})
    loop.(loop, parent, conn)
  else
    {:error, error} ->
      send(parent, {:socket, self(), :error, error: error})
      Api.warn(error: error)
  end
end

printable = fn line ->
  line
  |> String.split(~r/[[:graph:]]+/, include_captures: true)
  |> Enum.with_index()
  |> Enum.map(fn {chunk, i} ->
    case {rem(i, 2), chunk} do
      {0, ""} -> ""
      {0, chunk} -> ["[", :binary.encode_hex(chunk), "]"]
      {1, _} -> chunk
    end
  end)
  |> Enum.join("")
end

%{
  setup: setup,
  shift: shift,
  options: options,
  parse: modcmd.parse,
  printable: printable
}
