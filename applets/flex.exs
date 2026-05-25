use Terminal

case Api.path()
     |> Path.join("flex/**/*.ex")
     |> Path.wildcard()
     |> Kernel.ParallelCompiler.compile(return_diagnostics: true) do
  {:ok, _modules, _diagnostics} ->
    Api.debug("Compilation successful!")

  {:error, errors, diagnostics} ->
    Api.warn(diagnostics: diagnostics)
    Api.error(errors: errors)
end

Adb.reset()

Flex.run_loop("echo:44000", 1_000, Flex.EchoServer.Loop, port: 44000)
Flex.run_loop("slave:tcp:44001", 1_000, Flex.ModbusSlave.Loop, proto: "TCP", port: 44001)
Flex.run_loop("slave:rtu:44002", 1_000, Flex.ModbusSlave.Loop, proto: "RTU", port: 44002)

Flex.run_view("index.exs", Flex.Index, [])
Flex.run_view("login.exs", Flex.Login, [])
Flex.run_view("logout.exs", Flex.Logout, [])

Flex.eval_file("lib-modbus/setup.exs", [])
Flex.eval_file("/flex/serial-exports/setup.exs", [])
Flex.eval_file("/flex/socket-terminal/setup.exs", [])
Flex.eval_file("/flex/modbus-terminal/setup.exs", [])
Flex.eval_file("/flex/modbus-devices/setup.exs", [])
Flex.eval_file("/flex/user-backends/setup.exs", [])
Flex.eval_file("/flex/user-screens/setup.exs", [])
Flex.eval_file("/flex/user-scripts/setup.exs", [])
Flex.eval_file("/flex/user-files/setup.exs", [])

if Terminal.device?() do
  Flex.run_async("lib-browser.exs", url: "https://127.0.0.1", monitor: false, port: 0)
  Flex.run_view("config.exs", Flex.Config, [])
end

if Terminal.dev?() do
  Flex.run_view("ui-tester.exs", Flex.UITester, [])
end

:ok
