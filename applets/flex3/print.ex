defmodule Flex.Print do
  def tasks() do
    Applet.print_tree("flex3.exs")
  end

  def views() do
    Terminal.Multiple.lookup(:handler)
    |> Enum.map(fn {_, path} -> path end)
    |> Enum.sort()
    |> Enum.each(&IO.puts/1)
  end

  def nodes() do
    {:ok, names} = :net_adm.names(~c"127.0.0.1")

    names
    |> Enum.map(fn {name, port} -> "#{port} #{name}" end)
    |> Enum.each(&IO.puts/1)
  end
end
