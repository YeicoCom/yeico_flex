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
  Log.debug(exec: cmd, args: args, env: env)
  tag = Enum.join([cmd | args], " ")
  task = Api.async(fn -> loop.(cmd, loop) end, tag: "browser:exec:#{tag}")
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

  task = Api.async(fn -> exec.("udevd", [], []) end, tag: "browser:udevd")
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
  # from WEBKIT_INSPECTOR_HTTP_SERVER console
  # navigator.userAgent
  # "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/60.5 Safari/605.1.15"
  # {"COG_USER_AGENT", "CogWPEWebKit-YeicoTerminal"} does not work, see cli option below
  env = [{"XDG_RUNTIME_DIR", "/run/weston"}]
  # iex(1)> cmd "cog --help"
  # iex(1)> cmd "cog --help-all"

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
    "--user-agent=CogWPEWebKit-YeicoTerminal",
    "--ignore-tls-errors",
    "--bg-color=black",
    url
  ]

  # defer below gets ignored for System.cmd based exec
  Api.defer(fn -> exec.("killall", ["cog"], []) end)
  exec.("weston", args, env)
end

# test with:
# cmd "cogctl --system open https://google.com"
# cmd "killall cog" -> reboots weston
# cmd "killall weston" -> not reliable (see muontrap notes at the top)
# to address the load frame white screen error
monitor = fn ->
  local = Process.get(:local_count, 0)
  local? = Terminal.Multiple.lookup(:local)
  local = if local? == [], do: local + 1, else: 0
  Process.put(:local_count, local)
  if local >= 3, do: Log.warn("Reopen browser localhost at count #{local}")
  if local >= 3, do: System.shell("cogctl --system open https://127.0.0.1")
  weston = Process.get(:weston_count, 0)
  exes = Path.wildcard("/proc/*/exe")
  weston? = exes |> Enum.any?(&(File.read_link(&1) == {:ok, "/usr/bin/weston"}))
  cog? = exes |> Enum.any?(&(File.read_link(&1) == {:ok, "/usr/bin/cog"}))
  weston = if weston? and cog?, do: 0, else: weston + 1
  Process.put(:weston_count, weston)
  if weston >= 3, do: Log.warn("Killing weston/cog at count #{weston}")
  if weston >= 3, do: System.shell("killall weston; killall cog")
end

loop = fn args ->
  args.call.()
  Api.flush(toms: args.delay)
  args.loop.(args)
end

clean.()
Api.defer(clean)

Api.loop(loop, %{call: dbus, loop: loop, delay: 5_000}, rdms: 5_000, tag: "browser:dbus")
Api.loop(loop, %{call: udev, loop: loop, delay: 5_000}, rdms: 5_000, tag: "browser:udev")

# 400 works 10x on kingdel1, vm110, touch1
# 300 works 10x on vm110, touch1 fails on kingdel1
Api.sleep(400 + 200)

# short period because it may need seveal tries on reboot
Api.loop(loop, %{call: weston, loop: loop, delay: 1_000}, rdms: 5_000, tag: "browser:weston")

Api.loop(loop, %{call: monitor, loop: loop, delay: 2_000}, rdms: 5_000, tag: "browser:monitor")

# test with
# cmd "killall cog" -> reboots weston
# cmd "killall weston" -> not reliable (see muontrap notes at the top)
# cmd "cogctl --system open https://google.com"
# cmd "cogctl --system open https://127.0.0.1"
# cmd "ps | grep weston"
# cmd "ps | grep cog"
# Path.wildcard("/proc/*/exe") |> Enum.map(&File.read_link(&1)) |> Enum.any?(& &1=={:ok, "/usr/bin/weston"})
# cmd "ls -l /proc/*/exe"

# fn url -> exec.("cogctl", ["--system", "open", url], []) end

:ok
