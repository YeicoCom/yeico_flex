use Terminal.Live

Adb.reset()

# not needed in dev mode, left as reference
Api.evalf("flex3/code.exs")

Flex.Gauth.db_init()
Flex.Gauth.db_put("samuel.ventura@yeico.com")

# should not be really needed since serial export cleans on setup
System.shell("sudo killall socat", stderr_to_stdout: true)

Api.path()
|> Path.join("flex3/**/test/*.exs")
|> Path.wildcard()
|> Enum.map(&String.trim_leading(&1, Api.path()))
|> Enum.map(&String.trim_leading(&1, "/"))
|> Enum.each(&Api.evalf/1)

Api.evalf("flex3/tryout/echo1.exs")
Api.evalf("flex3/tryout/serials.exs")
Api.evalf("flex3/tryout/slaves.exs")
Api.evalf("flex3/tryout/device1.exs")
Api.evalf("flex3/tryout/logic1.exs")
Api.evalf("flex3/tryout/screen1.exs")
Api.evalf("flex3/tryout/password1.exs")
Api.evalf("flex3/tryout/modal1.exs")
Api.evalf("flex3/tryout/modal2.exs", path: "/modal2")
Api.evalf("flex3/tryout/hmi1.exs")
Api.evalf("flex3/tryout/gauth1.exs")
Api.evalf("flex3/tryout/forms.exs")
Api.evalf("flex3/tryout/vapid.exs", path: "/vapid")

Api.evalf("flex3/login.exs", path: "/login", props: %{})

:ok
