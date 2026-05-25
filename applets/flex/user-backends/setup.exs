use Flex

idb = Db.open("user-backends")
cdb = Db.open("backend-code")
Api.putcast!("flex:user-backends:items", [])
Api.putcast!("flex:user-backends:logs", %{})

Flex.run_view("code.exs", Flex.UserBackends.Code, cdb: cdb)
Flex.run_view("index.exs", Flex.UserBackends.Index, idb: idb, cdb: cdb)
Flex.run_loop("userbackends:loop", 2_000, Flex.UserBackends.Loop, idb: idb, cdb: cdb)

:ok
