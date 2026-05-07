use Terminal

defmodule Flex do
  defmacro __using__(_) do
    quote do
      use Terminal
      alias Flex.Db
      alias Flex.Mb
      alias Flex.Pt
      alias Flex.UI
      alias Flex.Lg
    end
  end

  defp run_async(fun) do
    env = Process.get(:__flex__)

    Api.async(fn ->
      Process.put(:__flex__, env)
      fun.()
    end)
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

  def eval_file(route, opts) do
    %{parent: parent, path: path} = get_path(route)
    # Log.debug(parent: parent, route: route, path: path)
    Process.put(:__flex__, Path.dirname(path))
    result = Api.evalf(path, opts)
    Process.put(:__flex__, parent)
    result
  end

  def eval_test(route, opts) do
    if Terminal.dev?() do
      if System.get_env("FLEX_TEST") do
        run_async(fn ->
          eval_file(route, opts)
        end)
      end
    end
  end

  def run_loop(dms, mod, opts) do
    setup = Function.capture(mod, :setup, 1)
    Api.loop(dms, setup, opts)
  end

  def run_view(route, mod, opts) do
    run_async(fn ->
      %{path: path} = get_path(route)
      # dir/index.exs -> dir
      # dir/other.exs -> dir/other
      path = path |> Path.rootname() |> String.replace_suffix("/index", "")
      # Log.debug(route: route, view: path)
      Terminal.view(path, mod.handler([{:path, path} | opts]))
      Api.sleep()
    end)
  end

  def eval_code(code, bindings) do
    Code.with_diagnostics(fn ->
      try do
        {:ok, Code.eval_string(code, bindings)}
      rescue
        error -> {:error, error}
      catch
        error -> {:error, error}
      end
    end)
  end

  def ui do
    Flex.UI.__info__(:functions)
    |> Enum.map(fn {k, v} -> {k, Function.capture(Flex.UI, k, v)} end)
    |> Enum.into(%{})
  end
end

defmodule Flex.Live do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      use Flex
    end
  end
end

Adb.reset()

Flex.eval_file("lib-logs.exs", [])
Flex.eval_file("lib-database.exs", [])
Flex.eval_file("lib-user-interface.exs", [])
Flex.eval_file("lib-modbus/setup.exs", [])
Flex.eval_file("lib-points.exs", [])

ui = Flex.ui()

Flex.eval_file("echo-server-loop.exs", [])
Flex.run_loop(1_000, Flex.EchoServer.Loop, port: 44000)

Flex.eval_file("/flex/serial-exports/setup.exs", ui: ui)
Flex.eval_file("/flex/socket-terminal/setup.exs", ui: ui)

Flex.eval_file("modbus-slave-loop.exs", [])

Flex.run_loop(1_000, Flex.ModbusSlave.Loop, proto: "TCP", port: 44001)
Flex.run_loop(1_000, Flex.ModbusSlave.Loop, proto: "RTU", port: 44002)

Flex.eval_file("/flex/modbus-terminal/setup.exs", ui: ui)
Flex.eval_file("/flex/modbus-devices/setup.exs", ui: ui)

Flex.eval_file("/flex/user-screens/setup.exs", ui: ui)
Flex.eval_file("/flex/user-scripts/setup.exs", ui: ui)

Flex.eval_file("index.exs", [])
Flex.run_view("index.exs", Flex.Index, ui: ui)

if Terminal.dev?() do
  Flex.eval_file("ui-tester.exs", [])
  Flex.run_view("ui-tester.exs", Flex.UITester, ui: ui)
end

:ok
