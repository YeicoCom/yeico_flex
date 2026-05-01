use Terminal

openDatabase = fn name ->
  path = Terminal.dpath("@home/flex.cubdb/#{name}")

  with {:ok, cubdb} <- CubDB.start_link(data_dir: path) do
    Adb.update("flex:databases", %{name => cubdb}, &Map.put(&1, name, cubdb))
    {:ok, cubdb}
  end
end

getDatabase = fn name ->
  Adb.get("flex:databases")[name]
end

:ok
