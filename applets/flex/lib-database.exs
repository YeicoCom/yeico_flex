use Terminal

open = fn name ->
  path = Terminal.dpath("@home/flex.db/#{name}")
  {:ok, db} = CubDB.start_link(data_dir: path)
  Adb.update("flex:databases", %{name => db}, &Map.put(&1, name, db))
end

api = fn name ->
  db = Adb.get("flex:databases")[name]

  %{
    select: fn opts -> CubDB.select(db, opts) end,
    put: fn key, value -> CubDB.put(db, key, value) end,
    get: fn key -> CubDB.get(db, key) end,
    delete: fn key -> CubDB.delete(db, key) end
  }
end

:ok
