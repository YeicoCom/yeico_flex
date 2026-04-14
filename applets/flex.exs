use Terminal

Api.putcast!("flex:serial:exports", [])
Api.putcast!("flex:serial:logs", %{})

{serial, _} = Api.evalf("flex/libserial.exs", path: Terminal.dpath("@home/flex.cubdb/serial"))

{ui, _} = Api.evalf("flex/libui.exs")
Api.evalf("flex/view.exs", path: "/flex", ui: ui)
Api.evalf("flex/serial-exports.exs", path: "/flex/serial-exports", ui: ui, serial: serial)

:ok
