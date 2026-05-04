use Terminal

iutils = flex.evalScript.("iutils.exs", mb: mb)
flex.evalView.("index.exs", iutils: iutils, ui: ui)

:ok
