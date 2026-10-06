alias Modbus.Slave
use Terminal

test = fn cmd, res ->
  ptcp = Modbus.TcpProtocol
  prtu = Modbus.RtuProtocol

  tid = Adb.get("flex:modbus-test:tid", 0)
  Adb.put("flex:modbus-test:tid", tid + 1)
  stcp = fn data -> Slave.apply(ptcp, "flex:modbus-test:model:tcp", data) end
  srtu = fn data -> Slave.apply(prtu, "flex:modbus-test:model:rtu", data) end

  req = ptcp.pack_req(cmd, tid)
  ^res = ptcp.parse_res(cmd, stcp.(req), tid)

  req = prtu.pack_req(cmd, nil)
  ^res = prtu.parse_res(cmd, srtu.(req), nil)
end

test.({:ri, 1, 2, 3}, [0, 0, 0])
test.({:rc, 1, 2, 3}, [0, 0, 0])
test.({:fc, 1, 2, [1, 0, 1]}, nil)
test.({:ri, 1, 2, 3}, [1, 0, 1])
test.({:rc, 1, 2, 3}, [1, 0, 1])

test.({:rir, 1, 2, 3}, [0, 0, 0])
test.({:rhr, 1, 2, 3}, [0, 0, 0])
test.({:phr, 1, 2, [3, 0, 0xFFFF]}, nil)
test.({:rir, 1, 2, 3}, [3, 0, 0xFFFF])
test.({:rhr, 1, 2, 3}, [3, 0, 0xFFFF])

:ok
