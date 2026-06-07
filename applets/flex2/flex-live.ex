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

  def view(path, handler, opts \\ []) do
    auth? = Keyword.get(opts, :auth?, false)
    auth = if auth?, do: %{key: :user, check: &check/1}
    Terminal.view(path, handler, auth: auth)
  end

  defp check({_path, _query, "admin"}), do: nil

  defp check({path, query, _user}) do
    to = Base.encode16(if(query, do: "#{path}?#{query}", else: path))
    "/flex2/login?to=#{to}"
  end
end
