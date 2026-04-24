use Terminal

device = fn ->
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

  %{
    new: new,
    shift: shift,
    options: options,
    open: open,
    exec: exec
  }
end

points = fn ->
  new = %{type: "RDI", slave: 1, address: 0, encoding: "none", names: ""}

  types = ["RDI", "RDO", "WDO", "RRI", "RRO", "WRO"]
  encodings = ["NONE", "F32BE", "F32LE", "U16BE", "U16LE"]

  options = %{
    types: types,
    encodings: encodings
  }

  toint? = fn str ->
    case Integer.parse(str) do
      {v, ""} -> v
      _ -> nil
    end
  end

  get = fn key ->
    Adb.get("flex:modbus-devices:point:#{key}", 0)
  end

  put = fn key, val ->
    Adb.put("flex:modbus-devices:point:#{key}", val)
  end

  # use official erlang type names
  type = fn
    "RDI", _ -> {:input, :boolean}
    "RDO", _ -> {:input, :boolean}
    "WDO", _ -> {:output, :boolean}
    "RRI", "F32BE" -> {:input, :float}
    "RRO", "F32BE" -> {:input, :float}
    "WRO", "F32BE" -> {:output, :float}
    "RRI", "F32LE" -> {:input, :float}
    "RRO", "F32LE" -> {:input, :float}
    "WRO", "F32LE" -> {:output, :float}
    "RRI", "U16BE" -> {:input, :uint16}
    "RRO", "U16BE" -> {:input, :uint16}
    "WRO", "U16BE" -> {:output, :uint16}
    "RRI", "U16LE" -> {:input, :uint16}
    "RRO", "U16LE" -> {:input, :uint16}
    "WRO", "U16LE" -> {:output, :uint16}
    "RRI", _ -> {:input, :uint16}
    "RRO", _ -> {:input, :uint16}
    "WRO", _ -> {:output, :uint16}
  end

  names = fn str ->
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end

  %{
    new: new,
    get: get,
    put: put,
    type: type,
    names: names,
    toint?: toint?,
    options: options,
    encoder: modcmd.encoder
  }
end

%{
  device: device.(),
  points: points.()
}
