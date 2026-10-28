defmodule Flex do
  use Terminal

  def dir(:entry) do
    Api.entry()
    |> Path.basename(".exs")
    |> Api.path()
  end

  def build() do
    :code.which(__MODULE__)
    |> Path.dirname()
  end
end
