use Terminal

new = fn ->
  %{
    name: "Local Slave",
    proto: "TCP",
    port: 44001,
    ip: "127.0.0.1",
    status: :disabled,
    delay: 20,
    points: []
  }
end

protos = ["TCP", "RTU"]
status = [:disabled, :enabled]

options = %{status: status, protos: protos}

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

open = fn ip, port, proto ->
  proto = libModbus.proto.(proto)
  libModbus.master.({:open, ip: ip, port: port, proto: proto})
end

exec = fn conn, cmd, opts ->
  libModbus.master.({:exec, conn, cmd, opts})
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

parse = fn params, points ->
  params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Map.update!(params, "delay", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{points: points})
end

points = fn devices, get ->
  for {id, device} <- devices do
    {id,
     for pi <- 0..(length(device.points) - 1)//1 do
       meta = device.meta[pi]
       for %{key: key} <- meta.points, do: {key, get.(key)}
     end
     |> List.flatten()
     |> Enum.into(%{})}
  end
  |> Enum.into(%{})
end

:ok
