defmodule Flex.Lg do
  use Flex

  defp post(key, id, error?, msg) do
    dt = NaiveDateTime.utc_now()
    Bus.broadcast!(key, %{id: id, dt: dt, error?: error?, msg: msg})
  end

  # error? nil to reset
  def send(key, id, error?, msg) when is_binary(msg), do: post(key, id, error?, msg)

  def send(key, id, error?, {:error, msg}) when is_binary(msg),
    do: post(key, id, error?, msg)

  def send(key, id, error?, {:error, msg}), do: post(key, id, error?, inspect(msg))
  def send(key, id, error?, msg), do: post(key, id, error?, inspect(msg))

  def replace(logs, log = %{id: id, error?: error?}) do
    case {error?, logs[id][:error?]} do
      {false, true} -> logs
      {_, _} -> Map.put(logs, id, Map.drop(log, [:id]))
    end
  end

  def shift(tzoffset, log = %{dt: dt}) do
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    %{log | dt: dt}
  end

  # {id, %{dt: dt}}
  def shift(tzoffset, logs) do
    logs
    |> Enum.map(fn {k, log} -> {k, shift(tzoffset, log)} end)
    |> Enum.into(%{})
  end
end
