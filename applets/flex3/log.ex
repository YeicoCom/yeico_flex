defmodule Flex3.Log do
  use Terminal

  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def trace(msg), do: log(:trace, msg)
  def debug(msg), do: log(:debug, msg)
  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)
  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)
  def log(level, msg), do: Api.log(level, inspect?(msg))
end
