use Terminal

db = db.open.("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})

plib = flex.evalScript.("points.exs", mb: mb, pt: pt)
flex.evalLoop.("loop.exs", db: db, mb: mb, plib: plib, dms: 2_000)
dlib = flex.evalScript.("logic.exs", plib: plib)
flex.evalView.("index.exs", dlib: dlib, plib: plib, ui: ui)
flex.evalScript.("publish.exs", plib: plib)

:ok
