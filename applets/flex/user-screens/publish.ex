defmodule Flex.UserScreens.Publish do
  use Flex

  def setup _ do
    Api.subget!("flex:user-screens:items")
    |> Enum.each(fn {id, %{route: route, name: name}} ->
      if String.starts_with?(route, "/") do
        Pt.put_value("screen:#{id}", route)
        Pt.reg_point("screen", "#{id}:#{name}")
      end
    end)

    Api.receive()
    [reload: __MODULE__]
  end
end

:ok
