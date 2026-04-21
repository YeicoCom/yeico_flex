use Terminal

Adb.reset()

Adb.put("flex:modbus:slave:model", %{})

Api.putcast!("flex:serial:exports", [])
Api.putcast!("flex:serial:logs", %{})

Api.putcast!("flex:modbus:devices", [])
Api.putcast!("flex:modbus:logs", %{})

{modbus, _} = Api.evalf("flex/libmodbus.exs")
{modcmd, _} = Api.evalf("flex/libmodcmd.exs")

dbpath = fn name -> Terminal.dpath("@home/flex.cubdb/#{name}") end

{ui, _} = Api.evalf("flex/libui.exs")
Api.evalf("flex/view.exs", path: "/flex", ui: ui)

{lib, _} = Api.evalf("flex/modbus-devices-lib.exs", modbus: modbus)
Api.evalf("flex/modbus-devices-loop.exs", path: dbpath.("modbus"), lib: lib)
Api.evalf("flex/modbus-devices-view.exs", path: "/flex/modbus-devices", ui: ui, lib: lib)

{lib, _} = Api.evalf("flex/modbus-terminal-lib.exs", modbus: modbus, modcmd: modcmd)
Api.evalf("flex/modbus-terminal-view.exs", path: "/flex/modbus-terminal", ui: ui, lib: lib)

{lib, _} = Api.evalf("flex/serial-exports-lib.exs")
Api.evalf("flex/serial-exports-loop.exs", path: dbpath.("serial"))
Api.evalf("flex/serial-exports-view.exs", path: "/flex/serial-exports", ui: ui, lib: lib)

{lib, _} = Api.evalf("flex/socket-terminal-lib.exs")
Api.evalf("flex/socket-terminal-view.exs", path: "/flex/socket-terminal", ui: ui, lib: lib)

if Terminal.dev?() do
  Api.evalf("flex/dev-ui-tester-view.exs", path: "/flex/dev-ui-tester", ui: ui)

  Api.evalf("flex/dev-modbus-slave-loop.exs",
    proto: modbus.tcp_proto,
    ip: "127.0.0.1",
    port: 44001
  )

  Api.evalf("flex/dev-modbus-slave-loop.exs",
    proto: modbus.rtu_proto,
    ip: "127.0.0.1",
    port: 44002
  )

  Api.evalf("flex/dev-modbus-slave-view.exs", path: "/flex/dev-modbus-slave", ui: ui)
end

:ok
