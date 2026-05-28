defmodule Flex.Logs do
  use Flex.Use.Live

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

  def append(logs, log = %{id: id, error?: error?}) do
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

  def render(assigns = %{logs: logs, id: id}) do
    assigns = Map.put(assigns, :log, logs[id])

    ~H"""
    <div :if={@status==:enabled and @log} class={["font-mono",
            @log.error? && "text-red-500",
            !@log.error? && "text-neutral-500",
          ]}>{@log.dt} {@log.msg}</div>
    """
  end
end
