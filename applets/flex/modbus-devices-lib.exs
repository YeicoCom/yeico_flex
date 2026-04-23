use Terminal

new = fn ->
  %{
    name: "LocalSlave",
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

points = %{
  types: ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"],
  encodings: ["NONE", "F32BE", "F32LE", "U16BE", "U16LE"]
}

options = %{status: status, protos: protos, points: points}

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

toproto = fn
  "TCP" -> modbus.tcp_proto
  "RTU" -> modbus.rtu_proto
end

open = fn ip, port, proto ->
  modbus.master.({:open, ip: ip, port: port, proto: toproto.(proto)})
end

exec = fn conn, cmd, opts ->
  modbus.master.({:exec, conn, cmd, opts})
end

names = fn str ->
  str
  |> String.split(",")
  |> Enum.map(&String.trim/1)
end

toint? = fn str ->
  case Integer.parse(str) do
    {v, ""} -> v
    _ -> nil
  end
end

get = fn key ->
  Adb.get("flex:modbus:point:#{key}", 0)
end

put = fn key, val ->
  Adb.put("flex:modbus:point:#{key}", val)
end

%{
  new: new,
  shift: shift,
  options: options,
  open: open,
  exec: exec,
  points: %{
    encoder: modcmd.encoder,
    new: %{type: "RDI", slave: 1, address: 0, encoding: "none", names: ""},
    toint?: toint?,
    names: names,
    get: get,
    put: put
  }
}
