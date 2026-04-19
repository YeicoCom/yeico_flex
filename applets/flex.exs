use Terminal

Api.putcast!("flex:serial:exports", [])
Api.putcast!("flex:serial:logs", %{})

Api.evalf("flex/loop-serial.exs", path: Terminal.dpath("@home/flex.cubdb/serial"))

{serial, _} = Api.evalf("flex/libserial.exs")
{modbus, _} = Api.evalf("flex/libmodbus.exs")

{ui, _} = Api.evalf("flex/libui.exs")
Api.evalf("flex/view.exs", path: "/flex", ui: ui)
# Api.evalf("flex/view-modbus-devices.exs", path: "/flex/modbus-devices", ui: ui, modbus: modbus)
Api.evalf("flex/view-modbus-terminal.exs", path: "/flex/modbus-terminal", ui: ui, modbus: modbus)
Api.evalf("flex/view-serial-exports.exs", path: "/flex/serial-exports", ui: ui, serial: serial)
Api.evalf("flex/view-socket-terminal.exs", path: "/flex/socket-terminal", ui: ui)
Api.evalf("flex/view-ui-tester.exs", path: "/flex/ui-tester", ui: ui)

:ok
