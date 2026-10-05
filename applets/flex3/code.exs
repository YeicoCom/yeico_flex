use Terminal

Api.path()
|> Path.join("flex3/_build")
|> (fn build ->
      Code.delete_path(build)
      Code.append_path(build)
    end).()

Api.path()
|> Path.join("flex3/_build/*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  # The BEAM runtime can hold exactly two versions of a module in memory at any given time
  :code.purge(m)
  :code.purge(m)
  :code.load_file(m)
end)

:ok
