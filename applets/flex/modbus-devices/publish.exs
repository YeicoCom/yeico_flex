defmodule Flex.ModbusDevices.Publish do
  alias Flex.ModbusDevices.PUtils
  use Flex

  defp schedule(bit, pulse, value, nil) do
    cond do
      value > 0 ->
        Pt.put_value(bit, 1)
        Process.send_after(self(), {:timer, bit, pulse, 0}, value)

      value < 0 ->
        Pt.put_value(bit, 0)
        Process.send_after(self(), {:timer, bit, pulse, 1}, -value)

      true ->
        nil
    end
  end

  defp schedule(_, _, _, _), do: nil

  defp pulse({keys, timers}) do
    receive do
      {:register, bit, pulse} ->
        value = Pt.subget_value(pulse)
        Pt.put_value(pulse, 0)
        timer = schedule(bit, pulse, value, nil)
        keys = Map.put(keys, pulse, bit)
        timers = Map.put(timers, pulse, timer)
        pulse({keys, timers})

      {:timer, bit, pulse, value} ->
        Pt.put_value(bit, value)
        timers = Map.put(timers, pulse, nil)
        pulse({keys, timers})

      {"flex:point:" <> _pulse, _, 0} ->
        pulse({keys, timers})

      {"flex:point:" <> pulse, _, value} ->
        timer = Map.get(timers, pulse)
        bit = Map.get(keys, pulse)
        Pt.put_value(pulse, 0)
        timer = schedule(bit, pulse, value, timer)
        timers = Map.put(timers, pulse, timer)
        pulse({keys, timers})

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  def setup _ do
    task = Api.async(&pulse/1, {%{}, %{}})

    Api.subget!("flex:modbus-devices:items")
    |> Enum.each(fn {_id, %{name: name, points: points}} ->
      Mdb.register!("flex:points:source", "status:#{name}")

      for point <- points do
        for %{dir: dir, tag: tag, key: key} <- PUtils.accessors(point) do
          Mdb.register!("flex:points:#{dir}", tag)

          if dir == :sink and String.starts_with?(tag, "bit:") do
            ptag = String.replace_prefix(tag, "bit:", "pulse:")
            Mdb.register!("flex:points:#{dir}", ptag)
            send(task.pid, {:register, key, "#{dir}:#{ptag}"})
          end
        end
      end
    end)

    receive do: (_ -> nil)
    Api.kill(task)
    :reload
  end
end

:ok
