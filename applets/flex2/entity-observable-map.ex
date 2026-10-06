defmodule Flex.ObservableMap do
  use Flex.Entity
  alias Applet.Api.Bus

  def put(pid_or_name, key, value) do
    pid = Utils.whereis(pid_or_name)
    send(pid, {:put, self(), key, value})
  end

  def get(pid_or_name, key) do
    pid = Utils.whereis(pid_or_name)
    send(pid, {:get, self(), key})

    receive do
      {:get, result} -> result
    after
      5_000 -> throw(timeout: {:get, pid_or_name, key})
    end
  end

  def subscribe!(name, key, arg \\ nil) do
    Bus.subscribe!({__MODULE__, name, key}, arg)
  end

  defp initial() do
    %{}
  end

  defp checks() do
    %{}
  end

  defp start(_, %{name: name}) do
    loop(name, %{})
  end

  defp clean(_, _) do
    :nop
  end

  defp loop(name, state) do
    receive do
      {:put, _caller, key, value} ->
        prev = state[key]
        state = Map.put(state, key, value)
        notify(name, key, prev, value)
        loop(name, state)

      {:get, caller, key} ->
        send(caller, {:get, state[key]})
        loop(name, state)
    end
  end

  defp notify(nil, _, _, _), do: :nop
  defp notify(_, _, same, same), do: :nop

  defp notify(name, key, _, value) do
    Bus.broadcast!({__MODULE__, name, key}, value)
  end
end
