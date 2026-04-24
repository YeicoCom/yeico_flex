use Terminal

Adb.reset()

{modbus, _} = Api.evalf("flex/libmodbus.exs", toms: 4_000)
{modcmd, _} = Api.evalf("flex/libmodcmd.exs", modbus: modbus)

dbpath = fn name -> Terminal.dpath("@home/flex.cubdb/#{name}") end

{ui, _} = Api.evalf("flex/lib-user-interface.exs")
Api.evalf("flex/view.exs", path: "/flex", ui: ui)

Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})
{lib, _} = Api.evalf("flex/modbus-devices-lib.exs", modbus: modbus, modcmd: modcmd)

Api.evalf("flex/modbus-devices-loop.exs",
  path: dbpath.("modbus-devices"),
  dms: 2_000,
  dlib: lib.device,
  plib: lib.points
)

Api.evalf("flex/modbus-devices-view.exs",
  path: "/flex/modbus-devices",
  ui: ui,
  dlib: lib.device,
  plib: lib.points
)

Api.evalf("flex/modbus-devices-publish.exs", dlib: lib.device, plib: lib.points)

{lib, _} = Api.evalf("flex/modbus-terminal-lib.exs", modbus: modbus, modcmd: modcmd)
Api.evalf("flex/modbus-terminal-view.exs", path: "/flex/modbus-terminal", ui: ui, lib: lib)

Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})
{lib, _} = Api.evalf("flex/serial-exports-lib.exs")
Api.evalf("flex/serial-exports-loop.exs", path: dbpath.("serial-exports"), dms: 2_000)
Api.evalf("flex/serial-exports-view.exs", path: "/flex/serial-exports", ui: ui, lib: lib)

Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})
{lib, _} = Api.evalf("flex/user-screens-lib.exs")
Api.evalf("flex/user-screens-loop.exs", path: dbpath.("user-screens"), dms: 2_000)
Api.evalf("flex/user-screens-view.exs", path: "/flex/user-screens", ui: ui, lib: lib)
Api.evalf("flex/user-screens-design.exs", path: "/flex/user-screens/design", ui: ui)

{lib, _} = Api.evalf("flex/socket-terminal-lib.exs", toms: 4_000)
Api.evalf("flex/socket-terminal-view.exs", path: "/flex/socket-terminal", ui: ui, lib: lib)

Api.evalf("flex/echo-server-loop.exs", dms: 1_000, ip: "127.0.0.1", port: 44000)

Adb.put("flex:modbus-slave:model", %{})

Api.evalf("flex/modbus-slave-loop.exs",
  dms: 1_000,
  proto: modbus.tcp_proto,
  ip: "127.0.0.1",
  port: 44001
)

Api.evalf("flex/modbus-slave-loop.exs",
  dms: 1_000,
  proto: modbus.rtu_proto,
  ip: "127.0.0.1",
  port: 44002
)

if Terminal.dev?() do
  Api.putcast!("flex:generic-items:items", [])
  Api.putcast!("flex:generic-items:logs", %{})

  {lib, _} = Api.evalf("flex/dev-generic-items-lib.exs")
  Api.evalf("flex/dev-generic-items-loop.exs", path: dbpath.("generic-items"), dms: 2_000)
  Api.evalf("flex/dev-generic-items-view.exs", path: "/flex/dev-generic-items", ui: ui, lib: lib)

  Api.evalf("flex/dev-ui-tester-view.exs", path: "/flex/dev-ui-tester", ui: ui)
end

:ok
