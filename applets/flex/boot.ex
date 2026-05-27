defmodule Flex.Boot do
  use Terminal

  defp get_path(route) do
    parent = Process.get(:__flex__) || "/flex"

    path =
      case String.starts_with?(route, "/flex") do
        false -> Path.join(parent, route)
        true -> route
      end

    %{parent: parent, path: path}
  end

  def eval_file(route, opts) do
    %{parent: parent, path: path} = get_path(route)
    Process.put(:__flex__, Path.dirname(path))
    result = Api.evalf(path, opts)
    Process.put(:__flex__, parent)
    result
  end

  def test(route, opts) do
    if Terminal.dev?() do
      if System.get_env("FLEX_TEST") do
        eval_file(route, opts)
      end
    end
  end

  def loop(tag, dms, mod, opts) do
    setup = Function.capture(mod, :setup, 1)
    Api.loop(tag, dms, setup, opts)
  end

  # dir/index.exs -> dir
  # dir/other.exs -> dir/other
  def view(route, mod, opts) do
    %{path: path} = get_path(route)
    path = Path.rootname(path) |> String.replace_suffix("/index", "")
    opts = [{:path, path} | opts]
    tag = Process.get(:__tag__)
    Process.put(:__tag__, "view:#{path}")
    Terminal.view(path, mod.handler(opts))
    Process.put(:__tag__, tag)
  end

  def run(fun) do
    fun.()
  end

  def tree() do
    Applet.print_tree("flex.exs")

    Terminal.Multiple.lookup(:handler)
    |> Enum.map(fn {_, path} -> path end)
    |> Enum.sort()
    |> Enum.each(&IO.puts/1)
  end
end
