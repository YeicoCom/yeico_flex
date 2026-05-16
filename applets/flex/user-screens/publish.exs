defmodule Flex.UserScreens.Publish do
  use Flex

  def setup _ do
    Api.subget!("flex:user-screens:items")
    |> Enum.each(fn {_id, screen} ->
      if screen.route != "" do
        Mdb.register!("flex:points:screen", "#{screen.route}:#{screen.name}")
      end
    end)

    Api.receive()
    :reload
  end
end

:ok
