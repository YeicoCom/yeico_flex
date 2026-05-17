use Flex

idb = Db.open("user-files")
fdb = Db.open("file-data")
Api.putcast!("flex:user-files:items", [])
Api.putcast!("flex:user-files:logs", %{})

Flex.eval_file("iutils.exs", [])
Flex.eval_file("loop.exs", [])
Flex.eval_file("index.exs", [])

Flex.run_view("index.exs", Flex.UserFiles.Index, idb: idb, fdb: fdb)
Flex.run_loop("userfiles:loop", 2_000, Flex.UserFiles.Loop, idb: idb, fdb: fdb)

:ok
