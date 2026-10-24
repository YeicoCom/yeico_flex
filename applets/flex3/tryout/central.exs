use Terminal

Flex.Gauth.db_init()
Flex.Gauth.db_put("samuel.ventura@yeico.com")
admin = "samuel.ventura@yeico.com"

view = %{path: "/", props: %{}}
shell = %{path: "/shell", props: %{}}

Api.evalf("flex3/login.exs", path: "/login", props: %{})
Api.evalf("flex3/central/boot.exs", view: view, shell: shell, props: %{}, admin: admin)

# test run setup locally
props = %{applet_css: "/applets/flex3.css", applet_js: "/applets/flex3.js"}
Api.evalf("flex3/central/slave/view.exs", path: "/setup", props: props)

:ok
