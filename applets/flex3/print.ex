defmodule Flex.Print do
  use Applet.Alias

  def tasks(route \\ "flex3.exs") do
    Applet.print_tree(route)
  end

  def views() do
    Terminal.Multiple.lookup(:handler)
    |> Enum.map(fn {_, path} -> path end)
    |> Enum.sort()
    |> Enum.each(&puts/1)
  end

  def nodes() do
    {:ok, names} = :net_adm.names(~c"127.0.0.1")

    names
    |> Enum.map(fn {name, port} -> "#{port} #{name}" end)
    |> Enum.each(&puts/1)
  end

  def adb() do
    Adb.list() |> Enum.each(&puts/1)
  end

  def mdb() do
    Mdb.list() |> Enum.each(&puts/1)
  end

  def udb() do
    Udb.list() |> Enum.each(&puts/1)
  end

  defp puts(term), do: IO.puts(Api.inspect?(term))
end
