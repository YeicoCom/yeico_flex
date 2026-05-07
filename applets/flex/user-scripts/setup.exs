use Flex

idb = Db.open("user-scripts")
cdb = Db.open("script-code")
Api.putcast!("flex:user-scripts:items", [])
Api.putcast!("flex:user-scripts:logs", %{})

Flex.eval_file("iutils.exs", [])
Flex.eval_file("loop.exs", [])
Flex.eval_file("index.exs", [])
Flex.eval_file("code.exs", [])

Flex.run_view("code.exs", Flex.UserScripts.Code, ui: ui, cdb: cdb)
Flex.run_view("index.exs", Flex.UserScripts.Index, ui: ui, idb: idb, cdb: cdb)
Flex.run_loop(2_000, Flex.UserScripts.Loop, idb: idb, cdb: cdb)

:ok
