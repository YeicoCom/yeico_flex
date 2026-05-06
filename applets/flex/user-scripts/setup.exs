use Terminal

idb = db.open.("user-scripts")
Api.putcast!("flex:user-scripts:items", [])
Api.putcast!("flex:user-scripts:logs", %{})

flex.evalLoop.("loop.exs", idb: idb, dms: 2_000)
iutils = flex.evalScript.("iutils.exs", [])
flex.evalView.("index.exs", iutils: iutils, ui: ui)
flex.evalView.("edit.exs", ui: ui)

:ok
