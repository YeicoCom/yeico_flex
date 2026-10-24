use Terminal

Flex.Gauth.db_init()
Flex.Gauth.db_put("samuel.ventura@yeico.com")

Api.evalf("flex3/login.exs", path: "/login", props: %{})
Api.evalf("flex3/wire/boot.exs", path: "/", props: %{})

:ok
