use Terminal

# Arguments
#
# parent: parent pid
# tty: the tty device path either /dev/ttyXXX or /dev/serial/by-id/SERIAL-ID
# bauds: the baud rate (9600, 19200, 115200, etc...)
# port: the tcp port to listen to
# local?: whether to bind to 127.0.0.1 or 0.0.0.0
#
# Requirements
#
# - socat
# - passwordless sudo or dialout user (not needed)
#
# Features
#
# - socat exits when stdio closes (pkill/muontrap not needed)
# - pkill not available in nerves buildroot

# /dev/tty.usbserial FTDI usb serial adapter on macos
# /dev/tty.usbmodem Honeywell Voyager XP 1472G Lector de Código de Barras Omnidireccional 1D/2D
# /dev/ttyACM cm4 serial ports seeed cm4 edgebox rpi 200
# /dev/ttyAMA cm4 serial ports waveshare cm4 io wireless base
# /tmp/tty.socat
#   sudo socat -d -d pty,link=/tmp/tty.socat.A pty,link=/tmp/tty.socat.B
#   sudo socat -d pty,link=/tmp/tty.socat.L TCP4-LISTEN:8001
#   sudo socat -d pty,link=/tmp/tty.socat.C TCP4:localhost:8001
#   nc -l 8001
#   nc localhost 8001

wrap = Api.wrapper()

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

open = fn {parent, tty, bauds, port, local?} ->
  addr = if local?, do: "127.0.0.1", else: "0.0.0.0"

  cmd =
    case :os.type() do
      {:unix, :linux} ->
        "socat TCP-LISTEN:#{port},bind=#{addr},reuseaddr #{tty},b#{bauds},raw,echo=0"

      {:unix, :darwin} ->
        "socat TCP-LISTEN:#{port},bind=#{addr},reuseadd #{tty},ispeed=#{bauds},ospeed=#{bauds},clocal=1,nonblock=1,raw,echo=0"
    end

  # sudo creates two processes
  cmd =
    case Terminal.user() do
      "root" -> cmd
      _ -> "sudo #{cmd}"
    end

  kill = fn pid ->
    Api.trace(tty: tty, kill: pid)
    System.cmd("kill", ["-9", "#{pid}"], stderr_to_stdout: true)
  end

  loop = fn loop, port ->
    receive do
      # both :eol and :noeol treated as full line
      {^port, {:data, {type, data}}} ->
        Api.trace(tty: tty, data: data)
        loop.(loop, port)

      {^port, {:data, data}} ->
        Api.trace(tty: tty, data: data)
        loop.(loop, port)

      unexpected ->
        Api.warn(tty: tty, unexpected: unexpected)
    end
  end

  check = fn ->
    # otherwise tty device gets created by socat under sudo
    case File.lstat(tty) do
      {:ok, stat = %File.Stat{type: :device}} ->
        Api.debug(tty: tty, stat: stat)
        true

      # serial/by-id links are relative
      {:ok, %File.Stat{type: :symlink}} ->
        with {:ok, path} <- File.read_link(tty),
             dir <- Path.dirname(tty),
             path <- Path.expand(path, dir),
             {:ok, stat = %File.Stat{type: :device}} <- File.lstat(path) do
          Api.debug(tty: tty, stat: stat)
          true
        else
          result ->
            raise("Invalid #{tty}: #{inspect(result)}")
        end

      result ->
        raise("Invalid #{tty}: #{inspect(result)}")
    end
  end

  serve = fn ->
    check.()
    Api.debug(tty: tty, cmd: cmd)
    port = Port.open({:spawn, cmd}, [:binary, :line])
    _ref = Port.monitor(port)
    {:os_pid, pid} = Port.info(port, :os_pid)
    Api.warn(tty: tty, pid: pid)
    Api.defer(fn -> kill.(pid) end)
    loop.(loop, port)
  end

  Api.async(serve)
end

fn
  :list ->
    list.()

  {:open, parent, tty, bauds, port, local?} ->
    wrap.(open).({parent, tty, bauds, port, local?})
end
