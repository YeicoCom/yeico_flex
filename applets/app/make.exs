dest =
  assets
  |> Path.join("lib/backend.ex")

assets
|> Path.dirname()
|> Path.join("flex3/lib/backend.ex")
|> File.cp(dest)

:ok
