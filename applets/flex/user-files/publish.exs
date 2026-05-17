defmodule Flex.UserFiles.Publish do
  alias Flex.UserFiles.IUtils
  use Flex

  def setup _ do
    Api.subget!("flex:user-files:items")
    |> Enum.each(fn {id, %{name: name}} ->
      link = IUtils.find(id)

      if link do
        Api.putcast!("flex:point:file:#{id}", "upload/#{link}")
        Mdb.register!("flex:points:file", "#{id}:#{name}")
      end
    end)

    Api.receive()
    :reload
  end
end

:ok
