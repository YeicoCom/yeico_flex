# Flex

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
:ok = Modbus.Session.exec(pid, {:fc, 1, 0, [1, 0, 1]})
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, {:rc, 1, 0, 3})
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, {:ri, 1, 0, 3})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 1})
{:ok, [1]} = Modbus.Session.exec(pid, {:rir, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, [0]})
{:ok, [0]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 1})
{:ok, [0]} = Modbus.Session.exec(pid, {:rir, 1, 0, 1})
:ok = Modbus.Session.exec(pid, {:phr, 1, 0, [1, 0, 1]})
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, {:rhr, 1, 0, 3})
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, {:rir, 1, 0, 3})
:ok = Modbus.Session.exec(pid, "s=1,a=0,c=wdo,d=1")
{:ok, [1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rdo,d=1")
{:ok, [1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rdi,d=1")
:ok = Modbus.Session.exec(pid, "s=1,a=0,c=wdo,d=101")
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rdo,d=3")
{:ok, [1, 0, 1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rdi,d=3")
:ok = Modbus.Session.exec(pid, "s=1,a=0,c=wro,d=1")
{:ok, [1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rro,d=1")
{:ok, [1]} = Modbus.Session.exec(pid, "s=1,a=0,c=rri,d=1")
:ok = Modbus.Session.exec(pid, "s=1,a=0,c=wro,d=1:0:2")
{:ok, [1, 0, 2]} = Modbus.Session.exec(pid, "s=1,a=0,c=rro,d=3")
{:ok, [1, 0, 2]} = Modbus.Session.exec(pid, "s=1,a=0,c=rri,d=3")
:ok = Modbus.Session.exec(pid, "s=1,a=0,c=wro,d=3.4,e=f32be")
Modbus.Session.exec(pid, "s=1,a=0,c=rro,d=1,e=f32be")
Modbus.Session.exec(pid, "s=1,a=0,c=rri,d=1,e=f32be")
:ok = Modbus.Session.close(pid)
```

## Fixme

- [ ] Observable map service
- [ ] Live screen service
- [ ] Service dependencies
- [ ] Modbus device pulse point
- [ ] Modbus integer 32 encodings
- [x] Modbus device point add
- [x] Reactive logic error handling
- [x] Reactive logic service
- [-] Modbus device point publish
- [-] Modbus point value timestamp
- [x] Modbus device point check
- [x] Modbus device service
- [x] Modbus session with command syntax
- [x] Modbus master session
- [x] Modbus slave service
- [x] Recheck config before run
- [x] Compiler gets stuck on macro errors
- [x] Compiler loads stalled source code
- [x] Wait for previous cleanup
- [x] Check testing
