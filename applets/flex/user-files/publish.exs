defmodule Flex.UserFiles.Publish do
  alias Flex.UserFiles.IUtils
  use Flex

  def setup _ do
    Bus.subscribe!("flex:user-files:update", nil)

    Api.subget!("flex:user-files:items")
    |> Enum.each(fn {id, %{name: name}} ->
      link = IUtils.find(id)

      if link do
        Pt.put_value("file:#{id}", "upload/#{link}")
        Pt.reg_point("file", "#{id}:#{name}")
      end
    end)

    Api.receive()
    :reload
  end
end

:ok
