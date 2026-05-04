use Terminal

db = db.open.("serial-exports")
Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})

flex.evalScript.("loop.exs", db: db, dms: 2_000)
logic = flex.evalScript.("logic.exs", [])
flex.evalView.("view.exs", logic: logic, ui: ui)

:ok
