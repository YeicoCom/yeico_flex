use Terminal

defmodule Flex.Tryout.Service do
  use Flex.Service
  use Terminal

  defp specs, do: %{}
  defp name(_), do: "tryout-deps"

  defp setup(_) do
    name = Process.get(:__name__)
    Log.debug(setup: name)
    clean(fn -> Log.debug(clean: name) end)
    clean(fn -> Api.sleep(500) end)
    ready()
    Api.receive()
  end
end

Flex.Tryout.Service.new()
|> Flex.Tryout.Service.run(rdms: 100, name: "s0", deps: [])

Flex.Tryout.Service.new()
|> Flex.Tryout.Service.run(rdms: 100, name: "s1", deps: ["s0"])

Flex.Tryout.Service.new()
|> Flex.Tryout.Service.run(rdms: 100, name: "s2", deps: ["s0", "s1"])

# Flex.Service.kill("s2") -> [] | [:ok] + respawn
# Flex.Service.stop("s2") -> [] | [:ok] + DOWN message
loop = fn loop, count ->
  Log.debug(kill: rem(count, 3))
  Flex.Service.kill("s#{rem(count, 3)}")
  # watch the task exit message after stop(name) call
  Api.flush(toms: 2000, level: :warn)
  loop.(loop, count + 1)
end

loop.(loop, 0)
