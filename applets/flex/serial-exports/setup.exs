use Flex

idb = Db.open("serial-exports")
Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})

Flex.run_view("index.exs", Flex.SerialExports.Index, idb: idb)
Flex.run_loop("serialexports:loop", 2_000, Flex.SerialExports.Loop, idb: idb)

:ok
