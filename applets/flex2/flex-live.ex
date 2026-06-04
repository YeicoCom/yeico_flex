defmodule Flex2.Live do
  defmacro __using__(_) do
    quote do
      import Phoenix.Component, except: [sigil_H: 2]
      import Terminal.Live, only: [sigil_H: 2, fui: 1]
      alias Phoenix.LiveView.JS
      import Phoenix.LiveView
      import Phoenix.HTML
      alias Flex2.Live
      alias Flex2.Log
    end
  end

  def view(path, handler), do: Terminal.view(path, handler)
end
