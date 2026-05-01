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

name = "Serial Export"

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

modal = fn
  {:edit, state, id, item = %{tty: tty}} ->
    ttys = [tty | list.()] |> Enum.uniq()
    options = Map.put(options, :ttys, ttys)

    Map.put(state, :modal, %{
      title: "Edit #{name}",
      item: item,
      id: id,
      opts: options
    })

  {:add, state} ->
    options = Map.put(options, :ttys, list.())

    Map.put(state, :modal, %{
      title: "Add #{name}",
      item: new,
      id: nil,
      opts: options
    })
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

apply = fn item, action ->
  case action do
    "enable" -> Map.put(item, :status, :enabled)
    "disable" -> Map.put(item, :status, :disabled)
    "local" -> Map.put(item, :ip, "127.0.0.1")
    "remote" -> Map.put(item, :ip, "0.0.0.0")
  end
end

parse = fn params ->
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "bauds", &String.to_integer/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{})
end

:ok
