# App

## Dev

- with flex3 dep in app.exs
- with runapp.exs tryout enabled
- works with both IO.inspect and Log.debug

```bash
terminal dev app.exs
```

## VM110

- with flex3 dep in app.exs
- with runapp.exs tryout enabled
- works with both IO.inspect only
- cmd "epmd -names" works
- :net_adm.names works
- :net_kernel.get_state() reports long names
- ping "yeico-8a53464d9e04" resolves to localnet ip
- ping "yeico-8a53464d9e04.local" fails to resolve
- :inet.gethostname() returns without local suffix
- :inet.gethostbyname('yeico-8a53464d9e04.local') error nxdomain
- :inet_db.add_host({127,0,0,1}, ['yeico-8a53464d9e04.local']) works
- now :inet.gethostbyname('yeico-8a53464d9e04.local') return 127.0.0.1
- even ping "yeico-8a53464d9e04.local" resolves to 127.0.0.1
- still connection fails on first attemp
- node defaults to :nocookie, Node.start sets random one
- fixed: fails to connect back to master node
- fixed: application exists but app not restarted
- node still pings back after application shutdown (if initial connection completed)
- need to add a halt to the stop application callback
- fixme: unable to compile with direct references to flex modules

```bash
terminal ssh vm110.yeico
terminal run vm110.yeico app.exs
```
