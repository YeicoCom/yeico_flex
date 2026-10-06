# Flex3

A micro service library

## Howto

```elixir
# modbus session against default tcp/rtu slave
{:ok, pid} = Modbus.Session.open(ip: "127.0.0.1", port: 4031, proto: Modbus.TcpProtocol)
{:ok, pid} = Modbus.Session.open(ip: "127.0.0.1", port: 4032, proto: Modbus.RtuProtocol)
:ok = Modbus.Session.exec(pid, {:fc, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:rc, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:ri, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:fc, 1, 0, [0]})
{:ok, [0]} = Modbus.Session.exec(pid, {:rc, 1, 0, 1})
{:ok, [0]} = Modbus.Session.exec(pid, {:ri, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:fc, 1, 0, [1, 0]})
{:ok, [1, 0]} = Modbus.Session.exec(pid, {:rc, 1, 0, 2})
{:ok, [1, 0]} = Modbus.Session.exec(pid, {:ri, 1, 0, 2})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:rir, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, [0]})
{:ok, [0]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 1})
{:ok, [0]} = Modbus.Session.exec(pid, {:rir, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, [1, 0]})
{:ok, [1, 0]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 2})
{:ok, [1, 0]} = Modbus.Session.exec(pid, {:rir, 1, 0, 2})
:ok = Modbus.Session.close(pid)
```

## Fixme

- [ ] Modbus device service
- [ ] Modbus with new command syntax
- [ ] Observable map service
- [ ] Reactive logic service
- [ ] Live screen service
- [ ] Service dependencies
- [x] Modbus master session
- [x] Modbus slave service
- [x] Check config before run
- [x] Compiler gets stuck on macro errors
- [x] Compiler loads stalled source code
- [x] Wait for previous cleanup
- [x] Check testing
