use Terminal.Live

# test with:
# Adb.list
# Flex.Points.put_value("sink:bit:D0", 1)
# Flex.Points.put_value("sink:bit:D0", 0)
# Flex.Points.put_value("sink:uint16:R0", 0)
# Flex.Points.put_value("sink:uint16:R0", 2)
Flex.ModbusDevice.new()
|> Flex.ModbusDevice.set(name: "device1")
|> Flex.ModbusDevice.set(ip: "127.0.0.1")
|> Flex.ModbusDevice.set(port: 4031)
|> Flex.ModbusDevice.set(proto: "TCP")
|> Flex.ModbusDevice.set(delay: 20)
|> Flex.ModbusDevice.add(%{type: "WDO", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"})
|> Flex.ModbusDevice.add(%{type: "RDI", slave: 1, address: 0, encoding: "NONE", names: "D0,D1"})
|> Flex.ModbusDevice.add(%{type: "WRO", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"})
|> Flex.ModbusDevice.add(%{type: "RRI", slave: 1, address: 0, encoding: "NONE", names: "R0,R1"})
|> Flex.ModbusDevice.run(rdms: 1000)

Flex.ModbusSlave.new()
|> Flex.ModbusSlave.set(key: "modbus:slave:tcp")
|> Flex.ModbusSlave.set(proto: "TCP")
|> Flex.ModbusSlave.set(ip: "127.0.0.1")
|> Flex.ModbusSlave.set(port: 4031)
|> Flex.ModbusSlave.run()

:ok
