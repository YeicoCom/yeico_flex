use Terminal

# MuonTrap kills the whole applet up to the root runner process
# MuonTrap kills parent erlang process on abnormal os-process exit
# MounTrap prevents weston from removing /run/weston/wayland-1 socket
# Full weston+cog restart on save is fast enough on vm110

loop = fn cmd, loop ->
  receive do
    {:io_request, from, reply_as, {:put_chars, encoding, line}} ->
      send(from, {:io_reply, reply_as, :ok})
      line = :unicode.characters_to_binary(line, encoding, :utf8)
      Log.trace("#{cmd} #{encoding} #{String.trim(line)}")
      loop.(cmd, loop)

    unexpected ->
      Log.warn(unexpected: unexpected)
  end
end

exec = fn cmd, args, env ->
  Log.debug(exec: cmd, args: args)
  task = Api.async(fn -> loop.(cmd, loop) end)
  into = IO.binstream(task.pid, :line)
  opts = [into: into, stderr_to_stdout: true, env: env]
  System.cmd(cmd, args, opts)
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

  task = Api.async(fn -> exec.("udevd", [], []) end)
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

  exec.("weston", args, env)
end

loop = fn args ->
  args.call.()
  Api.sleep(args.delay)
  args.loop.(args)
end

clean.()
Api.defer(clean)

Api.loop(5_000, loop, %{call: dbus, loop: loop, delay: 5_000})
Api.loop(5_000, loop, %{call: udev, loop: loop, delay: 5_000})

# 400 works 10x on kingdel1, vm110, touch1
# 300 works 10x on vm110, touch1 fails on kingdel1
Api.sleep(400 + 200)

# short period because it may need seveal tries on reboot
Api.loop(5_000, loop, %{call: weston, loop: loop, delay: 1_000})

# test with
# cmd "killall cog" -> reboots weston
# cmd "killall weston" -> weston wont return until cog is manually killed as well
# cmd "cogctl --system open https://google.com"
# cmd "cogctl --system open https://127.0.0.1"

:ok
