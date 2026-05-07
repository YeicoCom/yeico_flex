defmodule Flex.UserScripts.IUtils do
  use Flex

  @name "User Script"
  @status [:disabled, :enabled]
  @options %{status: @status}
  @new %{name: @name, status: :disabled}

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
    if force? || Adb.get("flex:user-scripts:item:#{id}") do
      Db.put(cdb, id, code)
    end

    Bus.broadcast!("flex:user-scripts:reload:#{id}", nil)
  end
end

:ok
