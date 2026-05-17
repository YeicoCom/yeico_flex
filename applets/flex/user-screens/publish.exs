defmodule Flex.UserScreens.Publish do
  use Flex

  def setup _ do
    Api.subget!("flex:user-screens:items")
    |> Enum.each(fn {id, %{route: route, name: name}} ->
      if String.starts_with?(route, "/") do
        Api.putcast!("flex:point:screen:#{id}", route)
        Mdb.register!("flex:points:screen", "#{id}:#{name}")
      end
    end)

    Api.receive()
    :reload
  end
end

:ok
