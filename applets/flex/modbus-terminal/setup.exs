use Terminal

logic = flex.evalScript.("logic.exs", mb: mb)
flex.evalView.("view.exs", logic: logic, ui: ui)

:ok
