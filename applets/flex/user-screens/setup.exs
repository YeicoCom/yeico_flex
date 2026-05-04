use Terminal

db = db.open.("user-screens")
Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})

flex.evalLoop.("loop.exs", db: db, dms: 2_000)
# vd = flex.evalScript.("validation.exs", [])
logic = flex.evalScript.("logic.exs", [])
flex.evalView.("index.exs", logic: logic, ui: ui, sd: %{})

:ok
