use Terminal

Wire.Db.init()
Api.evalf("flex3/wire/view.exs", path: path, props: props, auth: Flex.Gauth.get_spec(:db))
Api.loop(&Wire.Loop.setup/1, [], rdms: 1_000, tag: "wire:loop")

:ok
