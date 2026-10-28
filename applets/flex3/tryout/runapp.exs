use Terminal

Flex.BackendApp.new()
|> Flex.BackendApp.set(route: "app")
|> Flex.BackendApp.run(rdms: 1000, name: "app")

:ok
