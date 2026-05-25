use Flex

ddb = Db.open("screen-designs")
idb = Db.open("user-screens")
Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})

Flex.run_view("index.exs", Flex.UserScreens.Index, idb: idb, ddb: ddb)
Flex.run_view("view.exs", Flex.UserScreens.View, idb: idb, ddb: ddb, fid: nil)
Flex.run_view("design.exs", Flex.UserScreens.Design, ddb: ddb)
Flex.run_loop("userscreens:loop", 2_000, Flex.UserScreens.Loop, idb: idb, ddb: ddb)
Flex.run_loop("userscreens:publish", 0, Flex.UserScreens.Publish, [])

:ok
