use Flex

defmodule Flex.Point do
  def get(key), do: Flex.Pt.get_value(key)
  def put(key, value), do: Flex.Pt.put_value(key, value)
  def subget(key), do: Flex.Pt.subget_value(key)
  def publish(type, tag), do: Flex.Pt.reg_point(type, tag)
  def list(type), do: Flex.Pt.list(type)
end

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

Flex.eval_file("iutils.exs", [])
Flex.eval_file("loop.exs", [])
Flex.eval_file("index.exs", [])
Flex.eval_file("code.exs", [])

Flex.run_view("code.exs", Flex.UserScripts.Code, cdb: cdb)
Flex.run_view("index.exs", Flex.UserScripts.Index, idb: idb, cdb: cdb)
Flex.run_loop("userscripts:loop", 2_000, Flex.UserScripts.Loop, idb: idb, cdb: cdb)

:ok
