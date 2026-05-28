defmodule Flex.Logs do
  use Flex.Use.Live

  @take 4

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

  def append(logs, log = %{id: id}) do
    Map.update(logs, id, [log], fn list -> Enum.take([log | list], @take) end)
  end

  def shift(tzoffset, log = %{dt: dt}) do
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    %{log | dt: dt}
  end

  def shift(tzoffset, logs) when is_list(logs) do
    logs |> Enum.map(fn log -> shift(tzoffset, log) end)
  end

  # {id, %{dt: dt}}
  def shift(tzoffset, logs) do
    logs
    |> Enum.map(fn {k, list} -> {k, shift(tzoffset, list)} end)
    |> Enum.into(%{})
  end

  # show all on error
  # show last if not
  def render(assigns = %{logs: logs, id: id}) do
    list = Map.get(logs, id, [])
    error? = Enum.any?(list, & &1.error?)

    list =
      case {error?, list} do
        {true, _} -> Enum.reverse(list)
        {_, _} -> Enum.take(list, 1)
      end

    assigns = Map.put(assigns, :list, list)

    ~H"""
    <div :if={@status==:enabled} :for={log <- @list} class={["font-mono",
            log.error? && "text-red-500",
            !log.error? && "text-neutral-500",
          ]}>{log.dt} {log.msg}</div>
    """
  end
end
