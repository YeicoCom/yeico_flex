defmodule Flex2.Script.Utils do
  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def sleep(), do: Process.sleep(:infinity)
  def sleep(millis), do: Process.sleep(millis)
  def receive(), do: receive(do: (msg -> msg))
  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)
end

defmodule Flex2.Script do
  defmacro __using__(_) do
    quote do
      use Flex2.Live
      alias Flex2.Script.Utils
    end
  end
end
