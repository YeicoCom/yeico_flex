use Terminal

iutils = flex.evalScript.("iutils.exs", toms: 4_000)
flex.evalView.("index.exs", iutils: iutils, ui: ui)

:ok
