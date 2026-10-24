use Terminal

Api.evalf("flex3/central/view.exs",
  path: view.path,
  props: view.props,
  admin: admin,
  auth: Flex.Gauth.get_spec(:db)
)

Api.evalf("flex3/central/shell.exs",
  path: shell.path,
  props: shell.props,
  admin: admin,
  auth: Flex.Gauth.get_spec(:db)
)

Api.evalf("flex3/central/master.exs")

:ok
