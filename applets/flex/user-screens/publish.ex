defmodule Flex.UserScreens.Publish do
  use Flex.Use

  def setup _ do
    Api.subget!("flex:user-screens:items")
    |> Enum.each(fn {id, %{route: route, name: name}} ->
      if String.starts_with?(route, "/") do
        Points.put_value("screen:#{id}", route)
        Points.reg_point("screen", "#{id}:#{name}")
      end
    end)

    Api.receive()
    [reload: __MODULE__]
  end
end

:ok
