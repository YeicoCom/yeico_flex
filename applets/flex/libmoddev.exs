use Terminal

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

new = fn ->
  case Terminal.dev?() do
    true ->
      %{
        name: "LC",
        proto: "TCP",
        port: 502,
        ip: "10.77.0.10",
        status: :disabled
      }

    false ->
      %{
        name: "",
        proto: "RTU",
        port: 4401,
        ip: "127.0.0.1",
        status: :disabled
      }
  end
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

%{
  new: new,
  open: open,
  shift: shift,
  protos: protos,
  options: options,
  parse: modcmd.parse,
  master: modbus.master,
  printable: printable
}
