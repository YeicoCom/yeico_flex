defmodule Flex.SerialExports.IUtils do
  use Flex.Use

  def list do
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

  @bits ["8n1"]
  @name "Serial Export"
  @bauds [9600, 115_200]
  @ips ["127.0.0.1", "0.0.0.0"]
  @status [:enabled, :disabled]
  @options %{status: @status, bauds: @bauds, bits: @bits, ips: @ips}

  @new %{
    name: @name,
    tty: "/dev/ttyUSB0",
    bauds: 115_200,
    bits: "8n1",
    port: 4401,
    ip: "127.0.0.1",
    status: :enabled
  }

  def merge(item), do: Map.merge(@new, item)

  def modal(args) do
    case args do
      {:edit, state, id, item = %{tty: tty}} ->
        ttys = [tty | list()] |> Enum.uniq()
        options = Map.put(@options, :ttys, ttys)

        Map.put(state, :modal, %{
          title: "Edit #{@name}",
          item: item,
          id: id,
          opts: options
        })

      {:add, state} ->
        options = Map.put(@options, :ttys, list())

        Map.put(state, :modal, %{
          title: "Add #{@name}",
          item: @new,
          id: nil,
          opts: options
        })
    end
  end

  def index(pairs), do: Enum.map(pairs, fn {k, _} -> k end)

  def apply(item, action) do
    case action do
      "enable" -> Map.put(item, :status, :enabled)
      "disable" -> Map.put(item, :status, :disabled)
      "local" -> Map.put(item, :ip, "127.0.0.1")
      "remote" -> Map.put(item, :ip, "0.0.0.0")
    end
  end

  def parse(params) do
    params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Map.update!(params, "bauds", &String.to_integer/1)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    Enum.into(params, %{})
  end
end
