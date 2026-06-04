defmodule Flex2.Print do
  def tasks() do
    Applet.print_tree("flex2.exs")
  end

  def views() do
    Terminal.Multiple.lookup(:handler)
    |> Enum.map(fn {_, path} -> path end)
    |> Enum.sort()
    |> Enum.each(&IO.puts/1)
  end
end
