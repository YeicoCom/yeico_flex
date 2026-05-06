use Terminal

Adb.reset()

runAsync = fn fun ->
  env = Process.get(:__flex__)

  Api.async(fn ->
    Process.put(:__flex__, env)
    fun.()
  end)
end

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

evalScript = fn route, opts ->
  evalFile.(route, opts) |> mapBindings.()
end

evalTest = fn route, opts ->
  if Terminal.dev?() do
    if System.get_env("FLEX_TEST") do
      runAsync.(fn ->
        evalScript.(route, opts)
      end)
    end
  end
end

evalLoop = fn route, opts ->
  runAsync.(fn ->
    evalScript.(route, opts)
  end)
end

evalView = fn route, opts ->
  runAsync.(fn ->
    %{path: path} = getPath.(route)
    # dir/index.exs -> dir
    # dir/other.exs -> dir/other
    path = path |> Path.rootname() |> String.replace_suffix("/index", "")
    view = evalScript.(route, [{:path, path} | opts])
    # Api.debug(route: route, view: path)
    Terminal.view(path, view.handler)
    Api.sleep()
  end)
end

evalCode = fn code, bindings ->
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

flex = %{
  evalScript: evalScript,
  evalView: evalView,
  evalLoop: evalLoop,
  evalTest: evalTest,
  evalCode: evalCode
}

Adb.put("flex:api", flex)

mb = flex.evalScript.("lib-modbus/api.exs", [])
db = flex.evalScript.("lib-database.exs", [])
ui = flex.evalScript.("lib-user-interface.exs", [])
pt = flex.evalScript.("lib-points.exs", [])

flex.evalLoop.("echo-server-loop.exs", port: 44000, dms: 1_000)
flex.evalScript.("/flex/serial-exports/setup.exs", db: db, ui: ui)
flex.evalScript.("/flex/socket-terminal/setup.exs", db: db, ui: ui)

flex.evalLoop.("modbus-slave-loop.exs", mb: mb, proto: "TCP", port: 44001, dms: 1_000)
flex.evalLoop.("modbus-slave-loop.exs", mb: mb, proto: "RTU", port: 44002, dms: 1_000)
flex.evalScript.("/flex/modbus-terminal/setup.exs", mb: mb, ui: ui)
flex.evalScript.("/flex/modbus-devices/setup.exs", db: db, mb: mb, ui: ui, pt: pt)

flex.evalScript.("/flex/user-screens/setup.exs", db: db, ui: ui, pt: pt)
flex.evalScript.("/flex/user-scripts/setup.exs", db: db, ui: ui, pt: pt)

flex.evalView.("index.exs", ui: ui)

if Terminal.dev?() do
  flex.evalView.("ui-tester.exs", ui: ui)
end

:ok
