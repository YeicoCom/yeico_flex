use Terminal

protos = ["TCP", "RTU"]
options = %{protos: protos}

help = fn type -> mb.api.(:help, type) end
toproto = fn proto -> mb.api.(:parse, proto: proto) end

shift = fn tzoffset, log = %{dt: dt} ->
  dt = NaiveDateTime.shift(dt, hour: tzoffset)
  dt = NaiveDateTime.to_time(dt)
  %{log | dt: dt}
end

parse = fn line ->
  mb.api.(:parse, cmdline: line)
end

loop = fn loop, parent, conn ->
  tracer = fn type, data ->
    send(parent, {:socket, self(), type, data})
    :ok
  end

  receive do
    {:exec, %{cmd: cmd, get: get}} ->
      case mb.api.(:master, exec: {conn, cmd, tracer: tracer}) do
        {:ok, conn} ->
          send(parent, {:socket, self(), :success, :ok})
          loop.(loop, parent, conn)

        {:ok, conn, values} ->
          send(parent, {:socket, self(), :success, get.(values)})
          loop.(loop, parent, conn)

        {:error, _conn, error = :closed} ->
          send(parent, {:socket, self(), :error, error})
          Api.warn(error: error)

        {:error, conn, error} ->
          send(parent, {:socket, self(), :error, error})
          loop.(loop, parent, conn)
      end

    unexpected ->
      send(parent, {:socket, self(), :error, unexpected: unexpected})
      Api.warn(unexpected: unexpected)
  end
end

setup = fn {parent, %{ip: ip, port: port, proto: proto}} ->
  with {:ok, conn} <-
         mb.api.(:master, open: [ip: ip, port: port, proto: toproto.(proto)]) do
    send(parent, {:socket, self(), :success, "Connected to #{proto}:#{ip}:#{port}"})
    loop.(loop, parent, conn)
  else
    {:error, error} ->
      send(parent, {:socket, self(), :error, error: error})
      Api.warn(error: error)
  end
end

:ok
