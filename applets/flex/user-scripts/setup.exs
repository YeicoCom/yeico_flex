use Flex

defmodule Flex.Script do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      alias Flex.Point
    end
  end
end

idb = Db.open("user-scripts")
cdb = Db.open("script-code")
Api.putcast!("flex:user-scripts:items", [])
Api.putcast!("flex:user-scripts:logs", %{})

Flex.run_view("code.exs", Flex.UserScripts.Code, cdb: cdb)
Flex.run_view("index.exs", Flex.UserScripts.Index, idb: idb, cdb: cdb)
Flex.run_loop("userscripts:loop", 2_000, Flex.UserScripts.Loop, idb: idb, cdb: cdb)

:ok
