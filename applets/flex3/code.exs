use Terminal

build = Path.join(Api.path(), "flex3/_build")
Code.delete_path(build)
Code.append_path(build)

Api.path()
|> Path.join("flex3/_build/*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  :code.delete(m)
  :code.purge(m)
  :code.load_file(m)
end)

:ok
