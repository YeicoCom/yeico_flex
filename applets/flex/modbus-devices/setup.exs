use Terminal

db = db.open.("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})

plib = Adb.get("flex:api").evalScript.("points.exs", mb: mb, pt: pt)
Adb.get("flex:api").evalScript.("loop.exs", db: db, mb: mb, plib: plib, dms: 2_000)
dlib = Adb.get("flex:api").evalScript.("logic.exs", plib: plib)
view = Adb.get("flex:api").evalView.("view.exs", dlib: dlib, plib: plib, ui: ui)

:ok
