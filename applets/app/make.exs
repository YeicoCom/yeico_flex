dest =
  assets
  |> Path.join("lib/backend.ex")

assets
|> Path.dirname()
|> Path.join("flex3/backend.ex")
|> File.cp(dest)

:ok
