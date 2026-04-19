use Terminal

Api.putcast!("flex:serial:exports", [])
Api.putcast!("flex:serial:logs", %{})

Api.putcast!("flex:modbus:devices", [])
Api.putcast!("flex:modbus:logs", %{})

{term, _} = Api.evalf("flex/libterm.exs")
{serial, _} = Api.evalf("flex/libserial.exs")
{modbus, _} = Api.evalf("flex/libmodbus.exs")
{modcmd, _} = Api.evalf("flex/libmodcmd.exs")
{moddev, _} = Api.evalf("flex/libmoddev.exs", modcmd: modcmd, modbus: modbus)

Api.evalf("flex/loop-serial.exs", path: Terminal.dpath("@home/flex.cubdb/serial"))
Api.evalf("flex/loop-modbus.exs", path: Terminal.dpath("@home/flex.cubdb/modbus"), moddev: moddev)

{ui, _} = Api.evalf("flex/libui.exs")
Api.evalf("flex/view.exs", path: "/flex", ui: ui)
Api.evalf("flex/view-modbus-devices.exs", path: "/flex/modbus-devices", ui: ui, moddev: moddev)
Api.evalf("flex/view-modbus-terminal.exs", path: "/flex/modbus-terminal", ui: ui, moddev: moddev)
Api.evalf("flex/view-serial-exports.exs", path: "/flex/serial-exports", ui: ui, serial: serial)
Api.evalf("flex/view-socket-terminal.exs", path: "/flex/socket-terminal", ui: ui, term: term)
Api.evalf("flex/view-ui-tester.exs", path: "/flex/ui-tester", ui: ui)

:ok
