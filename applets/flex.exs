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

Adb.reset()

Flex.run_loop("echo:44000", 1_000, Flex.EchoServer.Loop, port: 44000)
Flex.run_loop("slave:tcp:44001", 1_000, Flex.ModbusSlave.Loop, proto: "TCP", port: 44001)
Flex.run_loop("slave:rtu:44002", 1_000, Flex.ModbusSlave.Loop, proto: "RTU", port: 44002)

Flex.run_view("index.exs", Flex.Index, [])
Flex.run_view("login.exs", Flex.Login, [])
Flex.run_view("logout.exs", Flex.Logout, [])

Flex.run(fn ->
  Flex.run_test("lib-modbus/modbus-test.exs", [])
  Flex.run_test("lib-modbus/convert-test.exs", [])
  Flex.run_test("lib-modbus/command-test.exs", [])
end)

Flex.run(fn ->
  idb = Flex.Db.open("serial-exports")
  Api.putcast!("flex:serial-exports:items", [])
  Api.putcast!("flex:serial-exports:logs", %{})

  Flex.run_view("serial-exports/index.exs", Flex.SerialExports.Index, idb: idb)
  Flex.run_loop("serialexports:loop", 2_000, Flex.SerialExports.Loop, idb: idb)
end)

Flex.run(fn ->
  idb = Flex.Db.open("modbus-devices")
  Api.putcast!("flex:modbus-devices:items", [])
  Api.putcast!("flex:modbus-devices:logs", %{})

  Flex.run_view("modbus-devices/index.exs", Flex.ModbusDevices.Index, idb: idb)
  Flex.run_loop("modbusdevices:loop", 2_000, Flex.ModbusDevices.Loop, idb: idb)
  Flex.run_loop("modbusdevices:publish", 0, Flex.ModbusDevices.Publish, [])
end)

Flex.run(fn ->
  Flex.run_view("socket-terminal/index.exs", Flex.SocketTerminal.Index, [])
end)

Flex.run(fn ->
  Flex.run_view("modbus-terminal/index.exs", Flex.ModbusTerminal.Index, [])
end)

Flex.run(fn ->
  idb = Flex.Db.open("user-backends")
  cdb = Flex.Db.open("backend-code")
  Api.putcast!("flex:user-backends:items", [])
  Api.putcast!("flex:user-backends:logs", %{})

  Flex.run_view("user-backends/code.exs", Flex.UserBackends.Code, cdb: cdb)
  Flex.run_view("user-backends/index.exs", Flex.UserBackends.Index, idb: idb, cdb: cdb)
  Flex.run_loop("userbackends:loop", 2_000, Flex.UserBackends.Loop, idb: idb, cdb: cdb)
end)

Flex.run(fn ->
  ddb = Flex.Db.open("screen-designs")
  idb = Flex.Db.open("user-screens")
  Api.putcast!("flex:user-screens:items", [])
  Api.putcast!("flex:user-screens:logs", %{})

  Flex.run_view("user-screens/index.exs", Flex.UserScreens.Index, idb: idb, ddb: ddb)
  Flex.run_view("user-screens/view.exs", Flex.UserScreens.View, idb: idb, ddb: ddb, fid: nil)
  Flex.run_view("user-screens/design.exs", Flex.UserScreens.Design, ddb: ddb)
  Flex.run_loop("userscreens:loop", 2_000, Flex.UserScreens.Loop, idb: idb, ddb: ddb)
  Flex.run_loop("userscreens:publish", 0, Flex.UserScreens.Publish, [])
end)

Flex.run(fn ->
  idb = Flex.Db.open("user-scripts")
  cdb = Flex.Db.open("script-code")
  Api.putcast!("flex:user-scripts:items", [])
  Api.putcast!("flex:user-scripts:logs", %{})

  Flex.run_view("user-scripts/code.exs", Flex.UserScripts.Code, cdb: cdb)
  Flex.run_view("user-scripts/index.exs", Flex.UserScripts.Index, idb: idb, cdb: cdb)
  Flex.run_loop("userscripts:loop", 2_000, Flex.UserScripts.Loop, idb: idb, cdb: cdb)
end)

Flex.run(fn ->
  idb = Flex.Db.open("user-files")
  Api.putcast!("flex:user-files:items", [])
  Api.putcast!("flex:user-files:logs", %{})
  udir = Terminal.dpath("@home/flex/upload")
  sdir = Api.path("static/upload")

  if {:ok, udir} != File.read_link(sdir) do
    {:ok, _} = File.rm_rf(sdir)
    :ok = File.ln_s(udir, sdir)
  end

  Flex.run_view("user-files/index.exs", Flex.UserFiles.Index, idb: idb, udir: udir)
  Flex.run_loop("userfiles:loop", 2_000, Flex.UserFiles.Loop, idb: idb, udir: udir)
  Flex.run_loop("userfiles:publish", 0, Flex.UserFiles.Publish, [])

  Flex.Pt.put_value("file:yeicologo", "logo.svg")
  Flex.Pt.reg_point("file", "yeicologo:Yeico Logo")
end)

if Terminal.device?() do
  Flex.eval_file("lib-browser.exs", url: "https://127.0.0.1", monitor: false, port: 0)
  Flex.run_view("config.exs", Flex.Config, [])
end

if Terminal.dev?() do
  Flex.run_view("ui-tester.exs", Flex.UITester, [])
end

:ok
