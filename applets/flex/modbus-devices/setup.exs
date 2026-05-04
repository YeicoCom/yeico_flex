use Terminal

idb = db.open.("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})

putils = flex.evalScript.("putils.exs", mb: mb, pt: pt)
flex.evalLoop.("loop.exs", idb: idb, mb: mb, putils: putils, dms: 2_000)
iutils = flex.evalScript.("iutils.exs", putils: putils)
flex.evalView.("index.exs", iutils: iutils, putils: putils, ui: ui)
flex.evalScript.("publish.exs", putils: putils)

:ok
