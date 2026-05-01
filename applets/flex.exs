use Terminal

Adb.reset()

getLibrary = fn name ->
  Adb.get("flex:libraries")[name]
end

mapBindings = fn {_result, bindings} ->
  for {key, value} <- bindings, reduce: %{} do
    lib ->
      case key |> to_string() |> String.ends_with?("_") do
        false -> Map.put(lib, key, value)
        true -> lib
      end
  end
end

# libraries do not depend on each other
toLibrary = fn path, name ->
  library = Api.evalf(path) |> mapBindings.()
  Adb.update("flex:libraries", %{name => library}, &Map.put(&1, name, library))
  library
end

evalScript = fn path, opts ->
  libs =
    Adb.get("flex:libraries")
    |> Enum.map(fn {n, v} -> {String.to_atom(n), v} end)

  opts = Keyword.merge(opts, libs)
  Api.evalf(path, opts) |> mapBindings.()
end

toLibrary.("flex/lib-convert.exs", "libConvert")
toLibrary.("flex/lib-points.exs", "libPoints")
toLibrary.("flex/lib-database.exs", "libDatabase")
toLibrary.("flex/lib-user-interface.exs", "libUserInterface")
toLibrary.("flex/lib-modbus.exs", "libModbus")
toLibrary.("flex/lib-modbus-command.exs", "libModbusCommand")

libDatabase = getLibrary.("libDatabase")

libDatabase.open.("serial-exports")
Api.putcast!("flex:serial-exports:items", [])
Api.putcast!("flex:serial-exports:logs", %{})
evalScript.("flex/serial-exports-loop.exs", dms: 2_000)
lib = evalScript.("flex/serial-exports-lib.exs", [])
evalScript.("flex/serial-exports-index.exs", path: "/flex/serial-exports", lib: lib)

evalScript.("flex/echo-server-loop.exs", dms: 1_000, port: 44000)
lib = evalScript.("flex/socket-terminal-lib.exs", toms: 4_000)
evalScript.("flex/socket-terminal-index.exs", path: "/flex/socket-terminal", lib: lib)

evalScript.("flex/modbus-slave-loop.exs", proto: "TCP", port: 44001, dms: 1_000)
evalScript.("flex/modbus-slave-loop.exs", proto: "RTU", port: 44002, dms: 1_000)
lib = evalScript.("flex/modbus-terminal-lib.exs", toms: 4_000)
evalScript.("flex/modbus-terminal-index.exs", path: "/flex/modbus-terminal", lib: lib)

libDatabase.open.("modbus-devices")
Api.putcast!("flex:modbus-devices:items", [])
Api.putcast!("flex:modbus-devices:logs", %{})
dlib = evalScript.("flex/modbus-devices-lib.exs", [])
plib = evalScript.("flex/modbus-devices-points.exs", [])
evalScript.("flex/modbus-devices-loop.exs", plib: plib, dlib: dlib, dms: 2_000)
lib = evalScript.("flex/modbus-devices-lib.exs", toms: 4_000)
evalScript.("flex/modbus-devices-index.exs", path: "/flex/modbus-devices", dlib: dlib, plib: plib)

evalScript.("flex/home-index.exs", path: "/flex")

if Terminal.dev?() do
  libDatabase.open.("dev-generic-items")
  Api.putcast!("flex:generic-items:items", [])
  Api.putcast!("flex:generic-items:logs", %{})

  lib = evalScript.("flex/dev-generic-items-lib.exs", [])
  evalScript.("flex/dev-generic-items-loop.exs", dms: 2_000)
  evalScript.("flex/dev-generic-items-index.exs", path: "/flex/dev-generic-items", lib: lib)

  evalScript.("flex/dev-ui-tester-view.exs", path: "/flex/dev-ui-tester")

  if System.get_env("TERMINAL_TEST") do
    evalScript.("flex/lib-convert-test.exs", [])
  end
end

:ok
