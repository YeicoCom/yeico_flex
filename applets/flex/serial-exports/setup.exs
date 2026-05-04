use Terminal

db = db.open.("serial-exports")
Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})

flex.evalLoop.("loop.exs", db: db, dms: 2_000)
logic = flex.evalScript.("logic.exs", [])
flex.evalView.("index.exs", logic: logic, ui: ui)

:ok
