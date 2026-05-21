defmodule Flex.UserBackends.IUtils do
  use Flex

  @name "User Backend"
  @status [:disabled, :enabled]
  @options %{status: @status}
  @new %{name: @name, status: :disabled}

  @template """
  defmodule Log do
    def trace(msg), do: log("trace", msg)
    def debug(msg), do: log("debug", msg)
    def info(msg), do: log("info", msg)
    def warn(msg), do: log("warn", msg)
    def error(msg), do: log("error", msg)
    defp log(level, msg) when is_binary(msg) do
      IO.puts([level, " ", msg])
      msg
    end
    defp log(level, msg) do
      log(level, inspect(msg))
      msg
    end
  end

  Log.info("hi")

  Process.sleep(:infinity)
  """

  def template, do: @template

  def style(:error), do: "text-red-500"
  def style(:warn), do: "text-yellow-500"
  def style(:info), do: "text-blue-500"
  def style(:debug), do: "text-teal-500"
  def style(:trace), do: "text-gray-500"
  def style(:unhandled), do: "text-red-700"

  def modal(args) do
    case args do
      {:edit, state, id, item} ->
        Map.put(state, :modal, %{
          title: "Edit #{@name}",
          item: item,
          id: id,
          opts: @options
        })

      {:add, state} ->
        Map.put(state, :modal, %{
          title: "Add #{@name}",
          item: @new,
          id: nil,
          opts: @options
        })
    end
  end

  def index(pairs), do: Enum.map(pairs, fn {k, _} -> k end)

  def apply(item, "enable"), do: Map.put(item, :status, :enabled)
  def apply(item, "disable"), do: Map.put(item, :status, :disabled)

  def parse(params) do
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    Enum.into(params, %{})
  end

  def load(cdb, id) do
    Db.get(cdb, id)
  end

  def save(cdb, id, code, force?) do
    if force? || Adb.get("flex:user-backends:item:#{id}") do
      Db.put(cdb, id, code)
    end

    Bus.broadcast!("flex:user-backends:reload:#{id}", nil)
  end
end

:ok
