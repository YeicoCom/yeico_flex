use Terminal

logic = flex.evalScript.("logic.exs", toms: 4_000)
flex.evalView.("view.exs", logic: logic, ui: ui)

:ok
