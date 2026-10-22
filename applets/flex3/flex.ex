defmodule Flex do
  use Terminal

  # logging requires __api__ for entry and route for both script and module functions
  # script functions require on definition wrapping for accurante stacktraces no matter the execution point
  # unwrapped script functions generate accurate stacktraces only when executed during the evaluation of their script file
  #
  # Api.wrap logs unhandled exceptions
  # Api.wrapper() does not
  def wrap(fun) when is_function(fun) do
    Api.wrapper().(fun)
  end

  def dir() do
    Api.entry()
    |> Path.basename(".exs")
    |> Api.path()
  end

  def build() do
    dir() |> Path.join("_build")
  end
end
