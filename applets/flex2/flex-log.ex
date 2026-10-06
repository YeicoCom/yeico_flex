defmodule Flex.Log do
  use Terminal
  alias Flex.Async

  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def trace(msg), do: log(:trace, msg)
  def debug(msg), do: log(:debug, msg)
  def info(msg), do: log(:info, msg)
  def warn(msg), do: log(:warn, msg)
  def error(msg), do: log(:error, msg)
  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)

  def log(level, msg) when is_binary(msg) do
    case Async.ctx() do
      %{id: id, module: module, log: log, mod?: mod?} ->
        # pidless for backend stdout logs
        pid? = Process.get(:pid?, true)
        msg = if(mod?, do: "#{inspect?(module)} #{msg}", else: msg)
        line = if(pid?, do: "#{inspect(self())} #{msg}", else: msg)
        route = "#{inspect?(module)}:#{id}"

        {bus, route} =
          case log do
            nil -> {:log, route}
            {log, route} -> {log, route}
          end

        broadcast!(bus, route, level, line)
        # fixme: setup a global switch
        Api.trace("#{level} #{route} #{msg}")
        msg

      nil ->
        Api.log(level, msg)
    end
  end

  def log(level, msg) do
    log(level, inspect?(msg))
    msg
  end

  def stamp(tzoffset, dt \\ nil) do
    (dt || NaiveDateTime.utc_now())
    |> NaiveDateTime.shift(hour: tzoffset)
    |> NaiveDateTime.truncate(:millisecond)
    |> NaiveDateTime.to_iso8601()
  end

  defp broadcast!(bus, route, level, msg) do
    Bus.broadcast!(bus, {route, level, msg})
    Bus.broadcast!({bus, route, level}, msg)
  end

  def subscribe!(level, route, sargs \\ nil)

  def subscribe!(:trace, route, sargs) do
    Bus.subscribe!({:log, route, :trace}, sargs)
    subscribe!(:debug, route, sargs)
  end

  def subscribe!(:debug, route, sargs) do
    Bus.subscribe!({:log, route, :debug}, sargs)
    subscribe!(:info, route, sargs)
  end

  def subscribe!(:info, route, sargs) do
    Bus.subscribe!({:log, route, :info}, sargs)
    Bus.subscribe!({:log, route, :warn}, sargs)
    Bus.subscribe!({:log, route, :error}, sargs)
  end
end
