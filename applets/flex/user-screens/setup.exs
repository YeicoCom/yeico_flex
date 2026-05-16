use Flex

ddb = Db.open("screen-designs")
idb = Db.open("user-screens")
Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})

Flex.eval_file("vutils.exs", [])
Flex.eval_file("button.exs", [])
Flex.eval_file("label.exs", [])
Flex.eval_file("link.exs", [])

Flex.eval_file("iutils.exs", [])
Flex.eval_file("dutils.exs", [])

Flex.eval_file("view.exs", [])
Flex.eval_file("loop.exs", [])
Flex.eval_file("index.exs", [])
Flex.eval_file("design.exs", [])
Flex.eval_file("publish.exs", [])

Flex.run_view("index.exs", Flex.UserScreens.Index, idb: idb, ddb: ddb)
Flex.run_view("view.exs", Flex.UserScreens.View, idb: idb, ddb: ddb, fid: nil)
Flex.run_view("design.exs", Flex.UserScreens.Design, ddb: ddb)
Flex.run_loop(2_000, Flex.UserScreens.Loop, idb: idb, ddb: ddb)
Flex.run_loop(0, Flex.UserScreens.Publish, [])

:ok
