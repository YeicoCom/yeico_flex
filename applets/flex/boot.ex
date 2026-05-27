defmodule Flex.Boot do
  use Terminal

  defp expand(path) do
    parent = Process.get(:__flex__) || "/flex"

    path =
      case String.starts_with?(path, "/flex") do
        false -> Path.join(parent, path)
        true -> path
      end

    %{parent: parent, path: path}
  end

  def eval(route, opts) do
    %{parent: parent, path: path} = expand(route)
    Process.put(:__flex__, Path.dirname(path))
    result = Api.evalf(path, opts)
    Process.put(:__flex__, parent)
    result
  end

  def test(route, opts) do
    if Terminal.dev?() do
      if System.get_env("FLEX_TEST") do
        eval(route, opts)
      end
    end
  end

  def loop(tag, dms, mod, opts) do
    setup = Function.capture(mod, :setup, 1)
    Api.loop(tag, dms, setup, opts)
  end

  def view(path, mod, opts) do
    %{path: path} = expand(path)
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
