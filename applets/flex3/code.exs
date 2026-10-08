use Terminal

build =
  Api.path()
  |> Path.join(__DIR__)
  |> Path.join("_build")

Code.delete_path(build)
Code.append_path(build)

build
|> Path.join("*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  :code.delete(m)
  :code.purge(m)
  :code.load_file(m)
end)

:ok
