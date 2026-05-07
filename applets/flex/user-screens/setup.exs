use Terminal

ddb = db.open.("screen-designs")
idb = db.open.("user-screens")
Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})

vutils = flex.evalScript.("vutils.exs", [])
button = flex.evalScript.("button.exs", ui: ui, pt: pt, vutils: vutils)
label = flex.evalScript.("label.exs", ui: ui, pt: pt, vutils: vutils)
items = [button, label]
dutils = flex.evalScript.("dutils.exs", ui: ui, pt: pt, ddb: ddb, vutils: vutils, items: items)
iutils = flex.evalScript.("iutils.exs", [])
flex.evalView.("index.exs", ui: ui, iutils: iutils, dutils: dutils)
flex.evalView.("design.exs", ui: ui, dutils: dutils)
flex.evalView.("view.exs", ui: ui, dutils: dutils, fid: nil)
opts = [ui: ui, dutils: dutils]
flex.evalLoop.("loop.exs", idb: idb, ddb: ddb, opts: opts, dms: 2_000)

:ok
