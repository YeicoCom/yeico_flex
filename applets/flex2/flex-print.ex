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

  # Flex2.Print.runners("backend/backend1.exs")
  def runners(id) do
    Applet.Api.Mdb.lookup({Flex2.Runner, id})
    |> Enum.map(fn {pid, payload} -> [{:pid, pid} | payload] end)
    |> Enum.each(&IO.inspect/1)
  end
end
