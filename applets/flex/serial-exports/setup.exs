use Terminal

idb = db.open.("serial-exports")
Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})

flex.evalLoop.("loop.exs", idb: idb, dms: 2_000)
iutils = flex.evalScript.("iutils.exs", [])
flex.evalView.("index.exs", iutils: iutils, ui: ui)

:ok
