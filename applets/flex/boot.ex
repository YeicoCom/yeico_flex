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

  def loop(tag, rdms, mod, opts) do
    setup = Function.capture(mod, :setup, 1)
    Api.loop(setup, opts, rdms: rdms, tag: tag)
  end

  def view(path, mod, opts) do
    %{path: path} = expand(path)
    opts = [{:path, path} | opts]
    tag = Process.get(:__tag__)
    Process.put(:__tag__, "view:#{path}")
    Terminal.view(path, mod.handler(opts), auth: auth(path))
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

  defp auth("/flex/login"), do: nil
  defp auth("/flex/logout"), do: nil

  defp auth(_) do
    check = fn
      {path, query, nil} ->
        to = Base.encode16(if(query, do: "#{path}?#{query}", else: path))
        "/flex/login?to=#{to}"

      {_path, _query, _user} ->
        nil
    end

    %{key: :user, check: check}
  end
end
