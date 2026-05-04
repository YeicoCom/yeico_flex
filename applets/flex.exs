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
  result = Api.evalf(path, [{:flex, Adb.get("flex:api")} | opts])
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
  evalView: evalView,
  evalTest: evalTest
}

Adb.put("flex:api", flex)

mb = flex.toLibrary.("lib-modbus/api.exs", [])
db = flex.toLibrary.("lib-database.exs", [])
ui = flex.toLibrary.("lib-user-interface.exs", [])
pt = flex.toLibrary.("lib-points.exs", [])

flex.evalScript.("echo-server-loop.exs", port: 44000, dms: 1_000)
flex.evalScript.("/flex/serial-exports/setup.exs", db: db, ui: ui)
flex.evalScript.("/flex/socket-terminal/setup.exs", db: db, ui: ui)

flex.evalScript.("modbus-slave-loop.exs", mb: mb, proto: "TCP", port: 44001, dms: 1_000)
flex.evalScript.("modbus-slave-loop.exs", mb: mb, proto: "RTU", port: 44002, dms: 1_000)
flex.evalScript.("/flex/modbus-terminal/setup.exs", mb: mb, ui: ui)
flex.evalScript.("/flex/modbus-devices/setup.exs", db: db, mb: mb, ui: ui, pt: pt)

flex.evalScript.("/flex/user-screens/setup.exs", db: db, ui: ui, pt: pt)

flex.evalView.("home-index.exs", ui: ui)

:ok
