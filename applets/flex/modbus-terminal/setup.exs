use Terminal

logic = Adb.get("flex:api").evalScript.("logic.exs", mb: mb)
view = Adb.get("flex:api").evalView.("view.exs", logic: logic, ui: ui)

:ok
