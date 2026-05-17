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
    path = path |> Path.rootname() |> String.replace_suffix("/index", "")
    opts = [{:path, path} | opts]

    Api.async("runview:#{path}", fn ->
      Terminal.view(path, mod.handler(opts))
      flush_loop()
    end)
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

defmodule Flex.Live do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      use Flex
    end
  end
end

Adb.reset()

Flex.await_many([
  Flex.eval_async("lib-logs.exs", []),
  Flex.eval_async("lib-login.exs", []),
  Flex.eval_async("lib-database.exs", []),
  Flex.eval_async("lib-user-interface.exs", []),
  Flex.eval_async("lib-modbus/setup.exs", []),
  Flex.eval_async("lib-points.exs", []),
  Flex.eval_async("echo-server-loop.exs", [])
])

Flex.await_many([
  Flex.eval_async("index.exs", []),
  Flex.eval_async("login.exs", []),
  Flex.eval_async("logout.exs", []),
  Flex.eval_async("modbus-slave-loop.exs", []),
  Terminal.dev?() && Flex.eval_async("ui-tester.exs", [])
])

Flex.run_loop("echo:44000", 1_000, Flex.EchoServer.Loop, port: 44000)
Flex.run_loop("slave:tcp:44001", 1_000, Flex.ModbusSlave.Loop, proto: "TCP", port: 44001)
Flex.run_loop("slave:rtu:44002", 1_000, Flex.ModbusSlave.Loop, proto: "RTU", port: 44002)

Flex.run_view("index.exs", Flex.Index, [])
Flex.run_view("login.exs", Flex.Login, [])
Flex.run_view("logout.exs", Flex.Logout, [])

Flex.run_async("/flex/serial-exports/setup.exs", [])
Flex.run_async("/flex/socket-terminal/setup.exs", [])
Flex.run_async("/flex/modbus-terminal/setup.exs", [])
Flex.run_async("/flex/modbus-devices/setup.exs", [])
Flex.run_async("/flex/user-screens/setup.exs", [])
Flex.run_async("/flex/user-scripts/setup.exs", [])

if Terminal.device?() do
  Flex.run_async("lib-browser.exs", url: "https://127.0.0.1", monitor: false, port: 0)
end

if Terminal.dev?() do
  Flex.run_view("ui-tester.exs", Flex.UITester, [])
end

:ok
