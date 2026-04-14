use Terminal

Api.putcast!("flex:serial:exports", [])

{serial, _} = Api.evalf("flex/libserial.exs", path: Terminal.dpath("@home/flex.cubdb/serial"))

{ui, _} = Api.evalf("flex/libui.exs")
Api.evalf("flex/view.exs", path: "/", ui: ui)
Api.evalf("flex/serial-exports.exs", path: "/serial-exports", ui: ui, serial: serial)

:ok
