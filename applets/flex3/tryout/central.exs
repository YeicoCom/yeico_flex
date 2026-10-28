use Terminal

Flex.Gauth.db_init()
Flex.Gauth.db_put("samuel.ventura@yeico.com")
admins = ["samuel.ventura@yeico.com"]
admin? = fn email -> email in admins end

Api.evalf("flex3/login.exs", props: %{})

Api.evalf("flex3/central/view.exs",
  path: "/",
  props: %{},
  admin?: admin?,
  auth: Flex.Gauth.get_spec(:db)
)

Api.evalf("flex3/central/shell.exs",
  path: "/shell",
  props: %{},
  admin?: admin?,
  auth: Flex.Gauth.get_spec(:db)
)

Api.evalf("flex3/central/master.exs")

# test run setup locally
props = %{applet_css: "/applets/flex3.css", applet_js: "/applets/flex3.js"}
Api.evalf("flex3/central/slave/view.exs", path: "/setup", props: props)

:ok
