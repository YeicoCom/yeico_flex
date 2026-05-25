defmodule Flex do
  use Terminal

  defmacro __using__(_) do
    quote do
      use Terminal
      alias Flex.Db
      alias Flex.Mb
      alias Flex.Pt
      alias Flex.UI
      alias Flex.Lg
      alias Flex.Ln
    end
  end

  defp get_path(route) do
    parent = Process.get(:__flex__) || "/flex"

    path =
      case String.starts_with?(route, "/flex") do
        false -> Path.join(parent, route)
        true -> route
      end

    %{parent: parent, path: path}
  end

  defp flush_loop() do
    receive do
      msg ->
        tag = Process.get(:__tag__)
        Log.debug(tag: tag, flush: msg)
        flush_loop()
    end
  end

  def await_many(list) do
    list
    |> Enum.filter(& &1)
    |> Task.await_many(:infinity)
  end

  def eval_async(route, opts) do
    ctx = Process.get(:__flex__)

    Api.async(
      "eval_async",
      fn ->
        Process.put(:__flex__, ctx)
        eval_file(route, opts)
      end
    )
  end

  def eval_file(route, opts) do
    %{parent: parent, path: path} = get_path(route)
    Process.put(:__flex__, Path.dirname(path))
    result = Api.evalf(path, opts)
    Process.put(:__flex__, parent)
    result
  end

  def eval_test(route, opts) do
    if Terminal.dev?() do
      if System.get_env("FLEX_TEST") do
        eval_file(route, opts)
      end
    end
  end

  def run_loop(tag, dms, mod, opts) do
    setup = Function.capture(mod, :setup, 1)
    Api.loop(tag, dms, setup, opts)
  end

  # dir/index.exs -> dir
  # dir/other.exs -> dir/other
  def run_view(route, mod, opts) do
    %{path: path} = get_path(route)
    path = Path.rootname(path) |> String.replace_suffix("/index", "")
    opts = [{:path, path} | opts]
    tag = Process.get(:__tag__)
    Process.put(:__tag__, "view:#{path}")
    Terminal.view(path, mod.handler(opts))
    Process.put(:__tag__, tag)
  end

  def run_async(route, opts) do
    ctx = Process.get(:__flex__)

    Api.async(
      "runasync:#{route}",
      fn ->
        Process.put(:__flex__, ctx)
        eval_file(route, opts)
        flush_loop()
      end
    )
  end

  def tree() do
    Applet.print_tree("flex.exs")
  end

  def view() do
    Terminal.Multiple.lookup(:handler)
    |> Enum.map(fn {_, path} -> path end)
    |> Enum.sort()
    |> Enum.each(&IO.puts/1)
  end
end
