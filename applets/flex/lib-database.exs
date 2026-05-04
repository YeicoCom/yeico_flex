use Terminal

api = fn name ->
  cubdb = Adb.get("flex:databases")[name]

  %{
    select: fn opts -> CubDB.select(cubdb, opts) end,
    put: fn key, value -> CubDB.put(cubdb, key, value) end,
    get: fn key -> CubDB.get(cubdb, key) end,
    delete: fn key -> CubDB.delete(cubdb, key) end
  }
end

open = fn name ->
  path = Terminal.dpath("@home/flex.cubdb/#{name}")
  {:ok, cubdb} = CubDB.start_link(data_dir: path)
  Adb.update("flex:databases", %{name => cubdb}, &Map.put(&1, name, cubdb))
  api.(name)
end

:ok
