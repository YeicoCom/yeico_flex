use Terminal

Adb.reset()

getPath = fn route ->
  parent = Process.get(:__flex__) || "/flex"

  path =
    case String.starts_with?(route, "/flex") do
      false -> Path.join(parent, route)
      true -> route
    end

  %{parent: parent, path: path}
end

evalFile = fn route, opts ->
  %{parent: parent, path: path} = getPath.(route)
  # Api.debug(parent: parent, route: route, path: path)
  Process.put(:__flex__, Path.dirname(path))
  result = Api.evalf(path, opts)
  Process.put(:__flex__, parent)
  result
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

toLibrary = fn route, opts ->
  library = evalFile.(route, opts) |> mapBindings.()
  Adb.update("flex:libraries", %{route => library}, &Map.put(&1, route, library))
  library
end

getLibrary = fn route ->
  Adb.get("flex:libraries")[route]
end

evalScript = fn route, opts ->
  evalFile.(route, opts) |> mapBindings.()
end

setConfig = fn key, value ->
  Adb.update("flex:config", %{key => value}, &Map.put(&1, key, value))
end

getConfig = fn key ->
  Adb.get("flex:config")[key]
end

evalTest = fn route, opts ->
  if Terminal.dev?() do
    if System.get_env("TERMINAL_TEST") do
      evalScript.(route, opts)
    end
  end
end

evalView = fn route, opts ->
  %{path: path} = getPath.(route)
  path = path |> Path.dirname()
  view = evalScript.(route, [{:path, path} | opts])

  Api.async(fn ->
    # Api.debug(route: route, view: path)
    Terminal.view(path, view.handler)
    Api.sleep()
  end)
end

flex = %{
  mapBindings: mapBindings,
  evalScript: evalScript,
  getLibrary: getLibrary,
  toLibrary: toLibrary,
  setConfig: setConfig,
  getConfig: getConfig,
  evalView: evalView,
  evalTest: evalTest
}

Adb.put("flex:api", flex)

mb = flex.toLibrary.("lib-modbus/api.exs", [])
db = flex.toLibrary.("lib-database.exs", [])
ui = flex.toLibrary.("lib-user-interface.exs", [])

flex.evalScript.("modbus-slave-loop.exs", mb: mb, proto: "TCP", port: 44001, dms: 1_000)
flex.evalScript.("modbus-slave-loop.exs", mb: mb, proto: "RTU", port: 44002, dms: 1_000)
flex.evalScript.("/flex/modbus-terminal/setup.exs", mb: mb, ui: ui)

# getLibrary = fn name ->
#   Adb.get("flex:libraries")[name]
# end

# mapBindings = fn {_result, bindings} ->
#   for {key, value} <- bindings, reduce: %{} do
#     lib ->
#       case key |> to_string() |> String.ends_with?("_") do
#         false -> Map.put(lib, key, value)
#         true -> lib
#       end
#   end
# end

# # libraries do not depend on each other
# toLibrary = fn path, name ->
#   library = Api.evalf(path) |> mapBindings.()
#   Adb.update("flex:libraries", %{name => library}, &Map.put(&1, name, library))
#   library
# end

# evalScript = fn path, opts ->
#   libs =
#     Adb.get("flex:libraries")
#     |> Enum.map(fn {n, v} -> {String.to_atom(n), v} end)

#   opts = Keyword.merge(opts, libs)
#   Api.evalf(path, opts) |> mapBindings.()
# end

# toLibrary.("flex/lib-convert.exs", "libConvert")
# toLibrary.("flex/lib-points.exs", "libPoints")
# toLibrary.("flex/lib-modbus.exs", "libModbus")
# toLibrary.("flex/lib-modbus-command.exs", "libModbusCommand")

# libDatabase = getLibrary.("libDatabase")

# libDatabase.open.("serial-exports")
# Api.putcast!("flex:serial-exports:items", [])
# Api.putcast!("flex:serial-exports:logs", %{})
# evalScript.("flex/serial-exports-loop.exs", dms: 2_000)
# lib = evalScript.("flex/serial-exports-lib.exs", [])
# evalScript.("flex/serial-exports-index.exs", path: "/flex/serial-exports", lib: lib)

# evalScript.("flex/echo-server-loop.exs", dms: 1_000, port: 44000)
# lib = evalScript.("flex/socket-terminal-lib.exs", toms: 4_000)
# evalScript.("flex/socket-terminal-index.exs", path: "/flex/socket-terminal", lib: lib)

# libDatabase.open.("modbus-devices")
# Api.putcast!("flex:modbus-devices:items", [])
# Api.putcast!("flex:modbus-devices:logs", %{})
# dlib = evalScript.("flex/modbus-devices-lib.exs", [])
# plib = evalScript.("flex/modbus-devices-points.exs", [])
# evalScript.("flex/modbus-devices-loop.exs", plib: plib, dlib: dlib, dms: 2_000)
# lib = evalScript.("flex/modbus-devices-lib.exs", toms: 4_000)
# evalScript.("flex/modbus-devices-index.exs", path: "/flex/modbus-devices", dlib: dlib, plib: plib)

# evalScript.("flex/home-index.exs", path: "/flex")

# if Terminal.dev?() do
#   libDatabase.open.("dev-generic-items")
#   Api.putcast!("flex:generic-items:items", [])
#   Api.putcast!("flex:generic-items:logs", %{})

#   lib = evalScript.("flex/dev-generic-items-lib.exs", [])
#   evalScript.("flex/dev-generic-items-loop.exs", dms: 2_000)
#   evalScript.("flex/dev-generic-items-index.exs", path: "/flex/dev-generic-items", lib: lib)

#   evalScript.("flex/dev-ui-tester-view.exs", path: "/flex/dev-ui-tester")

#   if System.get_env("TERMINAL_TEST") do
#     evalScript.("flex/lib-convert-test.exs", [])
#   end
# end

:ok
