use Terminal

Api.path()
|> Path.join("flex/_build")
|> (fn build ->
      Code.delete_path(build)
      Code.append_path(build)
    end).()

Api.path()
|> Path.join("flex/_build/*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  :code.purge(m)
  :code.load_file(m)
end)

alias Flex.Boot

Adb.reset()

Boot.loop("echo:44000", 1_000, Flex.EchoServer.Loop, port: 44000)
Boot.loop("slave:tcp:44001", 1_000, Flex.ModbusSlave.Loop, proto: "TCP", port: 44001)
Boot.loop("slave:rtu:44002", 1_000, Flex.ModbusSlave.Loop, proto: "RTU", port: 44002)

Boot.view("", Flex.Index, [])
Boot.view("login", Flex.Auth.Login, [])
Boot.view("logout", Flex.Auth.Logout, [])

Boot.run(fn ->
  Boot.test("lib-modbus/modbus-test.exs", [])
  Boot.test("lib-modbus/convert-test.exs", [])
  Boot.test("lib-modbus/command-test.exs", [])
end)

Boot.run(fn ->
  idb = Flex.Db.open("serial-exports")
  Api.putcast!("flex:serial-exports:items", [])
  Api.putcast!("flex:serial-exports:logs", %{})

  Boot.view("serial-exports", Flex.SerialExports.Index, idb: idb)
  Boot.loop("serialexports:loop", 2_000, Flex.SerialExports.Loop, idb: idb)
end)

Boot.run(fn ->
  idb = Flex.Db.open("modbus-devices")
  Api.putcast!("flex:modbus-devices:items", [])
  Api.putcast!("flex:modbus-devices:logs", %{})

  Boot.view("modbus-devices", Flex.ModbusDevices.Index, idb: idb)
  Boot.loop("modbusdevices:loop", 2_000, Flex.ModbusDevices.Loop, idb: idb)
  Boot.loop("modbusdevices:publish", 0, Flex.ModbusDevices.Publish, [])
end)

Boot.run(fn ->
  Boot.view("socket-terminal", Flex.SocketTerminal.Index, [])
end)

Boot.run(fn ->
  Boot.view("modbus-terminal", Flex.ModbusTerminal.Index, [])
end)

Boot.run(fn ->
  idb = Flex.Db.open("user-backends")
  cdb = Flex.Db.open("backend-code")
  Api.putcast!("flex:user-backends:items", [])
  Api.putcast!("flex:user-backends:logs", %{})

  Boot.view("user-backends/code", Flex.UserBackends.Code, cdb: cdb)
  Boot.view("user-backends", Flex.UserBackends.Index, idb: idb, cdb: cdb)
  Boot.loop("userbackends:loop", 2_000, Flex.UserBackends.Loop, idb: idb, cdb: cdb)
end)

Boot.run(fn ->
  ddb = Flex.Db.open("screen-designs")
  idb = Flex.Db.open("user-screens")
  Api.putcast!("flex:user-screens:items", [])
  Api.putcast!("flex:user-screens:logs", %{})

  Boot.view("user-screens", Flex.UserScreens.Index, idb: idb, ddb: ddb)
  Boot.view("user-screens/view", Flex.UserScreens.View, idb: idb, ddb: ddb, fid: nil)
  Boot.view("user-screens/design", Flex.UserScreens.Design, ddb: ddb)
  Boot.loop("userscreens:loop", 2_000, Flex.UserScreens.Loop, idb: idb, ddb: ddb)
  Boot.loop("userscreens:publish", 0, Flex.UserScreens.Publish, [])
end)

Boot.run(fn ->
  idb = Flex.Db.open("user-scripts")
  cdb = Flex.Db.open("script-code")
  Api.putcast!("flex:user-scripts:items", [])
  Api.putcast!("flex:user-scripts:logs", %{})

  Boot.view("user-scripts/code", Flex.UserScripts.Code, cdb: cdb)
  Boot.view("user-scripts", Flex.UserScripts.Index, idb: idb, cdb: cdb)
  Boot.loop("userscripts:loop", 2_000, Flex.UserScripts.Loop, idb: idb, cdb: cdb)
end)

Boot.run(fn ->
  idb = Flex.Db.open("user-files")
  Api.putcast!("flex:user-files:items", [])
  Api.putcast!("flex:user-files:logs", %{})
  udir = Terminal.dpath("@home/flex/upload")
  sdir = Api.path("static/upload")

  if {:ok, udir} != File.read_link(sdir) do
    {:ok, _} = File.rm_rf(sdir)
    :ok = File.ln_s(udir, sdir)
  end

  Boot.view("user-files", Flex.UserFiles.Index, idb: idb, udir: udir)
  Boot.loop("userfiles:loop", 2_000, Flex.UserFiles.Loop, idb: idb, udir: udir)
  Boot.loop("userfiles:publish", 0, Flex.UserFiles.Publish, [])

  Flex.Points.put_value("file:yeicologo", "logo.svg")
  Flex.Points.reg_point("file", "yeicologo:Yeico Logo")
end)

if Terminal.device?() do
  Boot.eval("lib-browser.exs", url: "https://127.0.0.1", monitor: true, port: 8899)
  Boot.view("config", Flex.ConfigView, [])
end

if Terminal.dev?() do
  Boot.view("ui-tester", Flex.UITester, [])
end

:ok
