defmodule Flex.Db do
  use Flex.Use

  defdelegate select(cubdb, opts), to: CubDB
  defdelegate put(cubdb, key, value), to: CubDB
  defdelegate get(cubdb, key), to: CubDB
  defdelegate delete(cubdb, key), to: CubDB
  defdelegate compact(cubdb), to: CubDB

  def open(name) do
    path = Terminal.dpath("@home/flex.cubdb/#{name}")
    {:ok, cubdb} = CubDB.start_link(data_dir: path)
    cubdb
  end
end
