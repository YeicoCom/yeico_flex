use Terminal

script = """
use Terminal
[setup, view, browser, css, js] = argv
File.mkdir_p!(Api.path("setup"))
File.write!(Api.path("setup.exs"), setup)
File.write!(Api.path("setup/view.exs"), view)
File.write!(Api.path("setup/browser.exs"), browser)
File.mkdir_p!(Api.path("static"))
File.write!(Api.path("static/setup.js"), js)
File.write!(Api.path("static/setup.css"), css)
Applet.start!("setup.exs")
"""

setup = File.read!(Api.path("flex/central/slave/setup.exs"))
view = File.read!(Api.path("flex/central/slave/view.exs"))
browser = File.read!(Api.path("flex/browser.exs"))
css = File.read!(Api.path("static/flex3.css"))
js = File.read!(Api.path("static/flex3.js"))
req = %{script: script, argv: [setup, view, browser, css, js]}

run = fn
  host = "yeico-" <> _ -> Terminal.Master.run(host, req) |> Log.trace()
  host -> Log.info("Slave ignored: #{host}")
end

loop = fn loop ->
  receive do
    {{:slave, :owner, nil}, _, %{host: host, name: name, live: true}} ->
      Log.info("Slave live #{host} #{name}")
      Api.async(fn -> run.(host) end)
      loop.(loop)

    unexpected ->
      Log.trace(unexpected: unexpected)
      loop.(loop)
  end
end

setup = fn ->
  Terminal.Publish.subscribe!({:slave, :owner, nil})

  for {_, %{host: host, name: name}} <- Terminal.slaves(nil) do
    Log.info("Slave boot #{host} #{name}")
    Api.async(fn -> run.(host) end)
  end

  loop.(loop)
end

Api.loop(setup, rdms: 4_000)

:ok
