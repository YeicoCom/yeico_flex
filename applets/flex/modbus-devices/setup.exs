use Flex

idb = Db.open("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})

Flex.run_view("index.exs", Flex.ModbusDevices.Index, idb: idb)
Flex.run_loop("modbusdevices:loop", 2_000, Flex.ModbusDevices.Loop, idb: idb)
Flex.run_loop("modbusdevices:publish", 0, Flex.ModbusDevices.Publish, [])

:ok
