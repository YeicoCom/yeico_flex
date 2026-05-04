use Terminal

logic = flex.evalScript.("logic.exs", mb: mb)
flex.evalView.("index.exs", logic: logic, ui: ui)

:ok
