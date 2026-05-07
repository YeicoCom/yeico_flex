use Terminal

idb = db.open.("user-scripts")
cdb = db.open.("script-code")
Api.putcast!("flex:user-scripts:items", [])
Api.putcast!("flex:user-scripts:logs", %{})

iutils = flex.evalScript.("iutils.exs", cdb: cdb)
flex.evalLoop.("loop.exs", idb: idb, cdb: cdb, iutils: iutils, dms: 2_000)
flex.evalView.("index.exs", iutils: iutils, ui: ui)
flex.evalView.("code.exs", ui: ui, iutils: iutils)

:ok
