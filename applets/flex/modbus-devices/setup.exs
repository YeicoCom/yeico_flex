use Flex

idb = Db.open("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})

Flex.eval_file("putils.exs", [])
Flex.eval_file("iutils.exs", [])
Flex.eval_file("index.exs", [])
Flex.eval_file("publish.exs", [])
Flex.eval_file("loop.exs", [])

Flex.run_view("index.exs", Flex.ModbusDevices.Index, ui: ui, idb: idb)
Flex.run_loop(2_000, Flex.ModbusDevices.Loop, idb: idb)
Flex.run_loop(0, Flex.ModbusDevices.Publish, [])

:ok
