use Terminal

list = fn ->
  (Path.wildcard("/dev/tty.usbserial*") ++
     Path.wildcard("/dev/tty.usbmodem*") ++
     Path.wildcard("/tmp/tty.socat.*") ++
     Path.wildcard("/dev/ttyACM*") ++
     Path.wildcard("/dev/ttyAMA*") ++
     Path.wildcard("/dev/ttyS*") ++
     Path.wildcard("/dev/ttyUSB*") ++
     Path.wildcard("/dev/serial/by-id/*"))
  |> Enum.sort()
end

new = %{
  tty: "/dev/ttyUSB0",
  bauds: 115_200,
  bits: "8n1",
  port: 4401,
  ip: "127.0.0.1",
  status: :enabled
}

bits = ["8n1"]
bauds = [9600, 115_200]
ips = ["127.0.0.1", "0.0.0.0"]
status = [:enabled, :disabled]
options = %{status: status, bauds: bauds, bits: bits, ips: ips}

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

%{
  new: new,
  list: list,
  shift: shift,
  options: options
}
