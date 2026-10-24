# Central

- ssh vm110.demos
- Terminal.wconfig!("master", "172.24.77.2:4443") # mbair.yeico
- Terminal.wconfig!("master", "172.24.79.1:4443") # mbair.demos
- check setup save: cat ~/.terminal/dev/config/*

## Shell

- multiline string results are auto split be pre tag
- charlists are treated as strings if ascii_printable?

```elixir
:os.cmd('find ~/.terminal')
:os.cmd('find ~/.terminal') |> to_string()
```
