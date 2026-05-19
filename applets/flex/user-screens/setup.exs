use Flex

ddb = Db.open("screen-designs")
idb = Db.open("user-screens")
Api.putcast!("flex:user-screens:items", [])
Api.putcast!("flex:user-screens:logs", %{})

Flex.eval_file("vutils.exs", [])

Flex.await_many([
  Flex.eval_async("_button.exs", []),
  Flex.eval_async("_label.exs", []),
  Flex.eval_async("_link.exs", []),
  Flex.eval_async("_image.exs", []),
  Flex.eval_async("_display.exs", []),
  Flex.eval_async("_capture.exs", []),
  Flex.eval_async("iutils.exs", [])
])

Flex.eval_file("dutils.exs", [])
Flex.eval_file("view.exs", [])

Flex.await_many([
  Flex.eval_async("loop.exs", []),
  Flex.eval_async("index.exs", []),
  Flex.eval_async("design.exs", []),
  Flex.eval_async("publish.exs", [])
])

Flex.run_view("index.exs", Flex.UserScreens.Index, idb: idb, ddb: ddb)
Flex.run_view("view.exs", Flex.UserScreens.View, idb: idb, ddb: ddb, fid: nil)
Flex.run_view("design.exs", Flex.UserScreens.Design, ddb: ddb)
Flex.run_loop("userscreens:loop", 2_000, Flex.UserScreens.Loop, idb: idb, ddb: ddb)
Flex.run_loop("userscreens:publish", 0, Flex.UserScreens.Publish, [])

:ok
