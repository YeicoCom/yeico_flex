defmodule Flex.ModbusDevices.Publish do
  alias Flex.ModbusDevices.PUtils
  use Flex

  defp timer(bit, value) do
    cond do
      value > 0 ->
        Pt.put_value(bit, 1)
        Process.send_after(self(), {:timer, bit, 0}, value)

      value < 0 ->
        Pt.put_value(bit, 0)
        Process.send_after(self(), {:timer, bit, 1}, -value)

      true ->
        :nop
    end
  end

  defp pulse(state) do
    receive do
      {:register, bit, pulse} ->
        value = Pt.subget_value(pulse)
        Pt.put_value(pulse, 0)
        timer(bit, value)
        pulse(Map.put(state, pulse, bit))

      {:timer, bit, value} ->
        Pt.put_value(bit, value)
        pulse(state)

      {"flex:point:" <> _pulse, _, 0} ->
        pulse(state)

      {"flex:point:" <> pulse, _, value} ->
        bit = Map.get(state, pulse)
        Pt.put_value(pulse, 0)
        timer(bit, value)
        pulse(state)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  def setup _ do
    task = Api.async(&pulse/1, %{})

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
