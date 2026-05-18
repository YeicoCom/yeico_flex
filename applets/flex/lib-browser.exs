use Terminal

# MuonTrap kills the whole applet up to the root runner process
# MuonTrap kills parent erlang process on abnormal os-process exit
# MounTrap prevents weston from removing /run/weston/wayland-1 socket
# MuonTrap detect weston killall and restarts weston but duplicates cog
# System.cmd wont return from weston exec despite weston killall until cog is manually killed as well
# Full weston+cog restart on save is fast enough on vm110
# 260516 giving MuonTrap a second chance now with trapping loops and tagged process tree
# 260516 going back to System.cmd because:
# - muontrap wont start weston with the added killall cog defer (just before weston exec)
# - some killall are being left behind
# - cog wont reliably restart on save

loop = fn cmd, loop ->
  receive do
    {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
      send(from, {:io_reply, reply_as, :ok})
      line = :unicode.characters_to_binary(line, encoding, :utf8)
      Log.trace("#{cmd} #{encoding} #{String.trim(line)}")
      loop.(cmd, loop)

    unexpected ->
      [unexpected: unexpected]
  end
end

exec = fn cmd, args, env ->
  Log.debug(exec: cmd, args: args)
  tag = Enum.join([cmd | args], " ")
  task = Api.async("browser:exec:#{tag}", fn -> loop.(cmd, loop) end)
  into = IO.binstream(task.pid, :line)
  opts = [into: into, stderr_to_stdout: true, env: env]
  res = System.cmd(cmd, args, opts)
  send(task.pid, res)
  cmd
end

clean = fn ->
  exec.("killall", ["cog"], [])
  exec.("killall", ["weston"], [])
  exec.("killall", ["udevd"], [])
  exec.("killall", ["udevadm"], [])
  exec.("killall", ["dbus-daemon"], [])
  File.rm_rf("/run/messagebus.pid")
end

dbus = fn ->
  # DBUS
  # /run/messagebus.pid
  # /run/dbus/system_bus_socket (stays after dbus-daemon exits)
  File.mkdir_p!("/run/dbus")
  File.rm_rf("/run/messagebus.pid")
  exec.("dbus-daemon", ["--system", "--nofork"], [])
end

udev = fn ->
  # UDEV
  # /run/udev/control (removed when udevd exists)

  task = Api.async("browser:udevd", fn -> exec.("udevd", [], []) end)
  exec.("udevadm", ["trigger", "--type=subsystems", "--action=add"], [])
  exec.("udevadm", ["trigger", "--type=devices", "--action=add"], [])
  exec.("udevadm", ["settle", "--timeout=30"], [])
  Api.await(task)
end

weston = fn ->
  # WESTON
  # /run/weston/wayland-1 (removed when weston exists)
  # /run/weston/wayland-1.lock (removed when weston exists)

  # card1-HDMI-A-1 card1-HDMI-A-2
  # card0-Virtual-1 proxmox
  # card1-DSI-1 touch7a
  # card1-LVDS-1 kingdel
  # card1-VGA-1 kingdel
  # card1-DP-1 kingdel

  Log.debug("weston waiting drm")

  Api.await(fn ->
    Path.wildcard("/sys/class/drm/card?-{DSI,HDMI,VGA,Virtual}-*/status")
    |> Enum.map(&File.read(&1))
    |> Enum.any?(&(&1 == {:ok, "connected\n"}))
  end)

  westini = """
  [core]
  shell=kiosk-shell.so
  require-input=false
  backend=drm

  # kingdel
  [output]
  name=LVDS-1
  mode=off
  """

  File.mkdir_p!("/run/weston")
  File.chmod!("/run/weston", 0o700)
  File.write!("/run/weston/weston.ini", westini)
  File.chmod!("/run/weston/weston.ini", 0o700)
  env = [{"XDG_RUNTIME_DIR", "/run/weston"}]

  # http://ip:port/
  # Requires BR2_PACKAGE_SHARED_MIME_INFO /usr/share/mime
  env =
    case monitor do
      port when is_integer(port) and port > 0 ->
        [{"WEBKIT_INSPECTOR_HTTP_SERVER", "0.0.0.0:#{port}"} | env]

      _ ->
        env
    end

  args = [
    "--log=/run/weston/weston.log",
    "--config=/run/weston/weston.ini",
    "--",
    "/usr/bin/cog",
    "--ignore-tls-errors",
    "--bg-color=black",
    url
  ]

  # defer below gets ignored for System.cmd based exec
  Api.defer(fn -> exec.("killall", ["cog"], []) end)
  exec.("weston", args, env)
end

# test with cmd "cogctl --system open https://google.com"
# to address the load frame white screen error
monitor = fn ->
  count = Process.get(:count, 0)
  local = Terminal.Multiple.lookup(:local)
  count = if local == [], do: count + 1, else: 0
  Process.put(:count, count)
  if count >= 5, do: Log.warn("Reopen browser localhost at count #{count}")
  if count >= 5, do: System.shell("cogctl --system open https://127.0.0.1")
end

loop = fn args ->
  args.call.()
  Api.flush(args.delay)
  args.loop.(args)
end

clean.()
Api.defer(clean)

Api.loop("browser:dbus", 5_000, loop, %{call: dbus, loop: loop, delay: 5_000})
Api.loop("browser:udev", 5_000, loop, %{call: udev, loop: loop, delay: 5_000})

# 400 works 10x on kingdel1, vm110, touch1
# 300 works 10x on vm110, touch1 fails on kingdel1
Api.sleep(400 + 200)

# short period because it may need seveal tries on reboot
Api.loop("browser:weston", 5_000, loop, %{call: weston, loop: loop, delay: 1_000})

Api.loop("browser:monitor", 5_000, loop, %{call: monitor, loop: loop, delay: 1_000})

# test with
# cmd "killall cog" -> reboots weston
# cmd "killall weston" -> not reliable (see muontrap notes at the top)
# cmd "cogctl --system open https://google.com"
# cmd "cogctl --system open https://127.0.0.1"
# cmd "ps | grep weston"
# cmd "ps | grep cog"
# Path.wildcard("/proc/*/exe") |> Enum.map(&File.read_link(&1)) |> Enum.any?(& &1=={:ok, "/usr/bin/weston"})
# cmd "ls -l /proc/*/exe"

:ok
