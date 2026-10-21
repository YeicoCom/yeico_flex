use Terminal.Live

# test with
# {:ok, pid} = Modbus.Session.open(ip: "127.0.0.1", port: 4031, proto: Modbus.TcpProtocol)
# :ok = Modbus.Session.exec(pid, "s=1,a=0,c=wdo,d=1")
# Adb.get("modbus:slave:tcp")
Flex.ModbusSlave.new()
|> Flex.ModbusSlave.set(key: "modbus:slave:tcp")
|> Flex.ModbusSlave.set(proto: "TCP")
|> Flex.ModbusSlave.set(ip: "127.0.0.1")
|> Flex.ModbusSlave.set(port: 4031)
|> Flex.ModbusSlave.run()

# test with
# {:ok, pid} = Modbus.Session.open(ip: "127.0.0.1", port: 4032, proto: Modbus.RtuProtocol)
# :ok = Modbus.Session.exec(pid, "s=1,a=0,c=wdo,d=1")
# Adb.get("modbus:slave:rtu")
Flex.ModbusSlave.new()
|> Flex.ModbusSlave.set(key: "modbus:slave:rtu")
|> Flex.ModbusSlave.set(proto: "RTU")
|> Flex.ModbusSlave.set(ip: "127.0.0.1")
|> Flex.ModbusSlave.set(port: 4032)
|> Flex.ModbusSlave.run()

:ok
