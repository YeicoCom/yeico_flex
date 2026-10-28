use Terminal.Live

Adb.reset()

# not needed in dev mode, left as reference
Api.evalf("flex3/code.exs")

Api.path()
|> Path.join("flex3/**/test/*.exs")
|> Path.wildcard()
|> Enum.map(&String.trim_leading(&1, Api.path()))
|> Enum.map(&String.trim_leading(&1, "/"))
|> Enum.each(&Api.evalf/1)

Adb.reset()

Api.path()
|> Path.join("flex3/tryout/enabled/*.exs")
|> Path.wildcard()
|> Enum.map(&String.trim_leading(&1, Api.path()))
|> Enum.map(&String.trim_leading(&1, "/"))
|> Enum.map(&String.replace(&1, "/enabled/", "/"))
|> Enum.filter(&(!File.exists?(&1)))
|> Enum.each(&Api.evalf/1)

:ok
