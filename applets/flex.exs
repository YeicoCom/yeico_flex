use Terminal

Api.putcast!("flex:serial:exports", [])
Api.putcast!("flex:serial:logs", %{})

Api.putcast!("flex:modbus:devices", [])
Api.putcast!("flex:modbus:logs", %{})

{serial, _} = Api.evalf("flex/libserial.exs")
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

Api.evalf("flex/view-ui-tester.exs", path: "/flex/ui-tester", ui: ui)

:ok
