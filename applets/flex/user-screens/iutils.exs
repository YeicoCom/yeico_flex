defmodule Flex.UserScreens.IUtils do
  @name "User Screen"
  @new %{name: @name, route: "", password: "", status: :disabled}
  @status [:disabled, :enabled]
  @options %{status: @status}

  def modal(args) do
    case args do
      {:edit, state, id, item} ->
        Map.put(state, :modal, %{
          title: "Edit #{@name}",
          type: :edit,
          item: item,
          id: id,
          opts: @options
        })

      {:add, state} ->
        Map.put(state, :modal, %{
          title: "Add #{@name}",
          type: :edit,
          item: @new,
          id: nil,
          opts: @options
        })

      {:paste, state} ->
        Map.put(state, :modal, %{
          title: "Paste User Screen",
          type: :paste
        })
    end
  end

  def index(pairs), do: Enum.map(pairs, fn {k, _} -> k end)

  def apply(item, action) do
    case action do
      "enable" -> Map.put(item, :status, :enabled)
      "disable" -> Map.put(item, :status, :disabled)
    end
  end

  def parse(params) do
    params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
    params = Map.update!(params, "route", &String.trim/1)
    params = Map.update!(params, "password", &String.trim/1)
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    Enum.into(params, %{})
  end

  def password?(""), do: nil
  def password?(password), do: password
end

:ok
