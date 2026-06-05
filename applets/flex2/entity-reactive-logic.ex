defmodule Flex2.ReactiveLogic do
  use Flex2.Entity

  def add(entity, fun, args \\ []) do
    Setter.check("fun", fun, {:fun, 1})
    Setter.check("args", args, {:list, nil, &check(&1, &2, :arg)})
    %{funs: funs} = entity
    funs = [{fun, args} | funs]
    Map.put(entity, :funs, funs)
  end

  defp initial() do
    %{
      map: nil,
      funs: []
    }
  end

  defp checks() do
    %{
      map: :binary,
      funs: {:list, nil, &check(&1, &2, :fun)}
    }
  end

  defp start(%{map: map, funs: funs}, _) do
    tag = Async.tag()

    for {{fun, args}, index} <- funs |> Enum.reverse() |> Enum.with_index() do
      Async.spawn("#{tag}:fun:#{index}", fn -> setup(map, index, fun, args) end)
    end

    Utils.receive()
  end

  defp clean(_, _) do
    :nop
  end

  defp setup(map, index, fun, args) do
    pid = Utils.whereis(map)

    inputs =
      for {arg, spec} <- args, reduce: %{} do
        inputs ->
          case spec do
            {:const, const} ->
              Map.put(inputs, arg, const)

            {:point, point} ->
              Flex2.ObservableMap.subscribe!(map, point, arg)
              val = Flex2.ObservableMap.get(pid, point)
              Map.put(inputs, arg, val)

            {:timer, ms} ->
              Process.send_after(self(), {:timer, arg, ms}, ms)
              Map.put(inputs, arg, 0)
          end
      end

    log = fn level, term ->
      Log.log(level, "fun:#{index} #{Log.inspect?(term)}")
    end

    ctx = fn inputs, state, event ->
      %{
        state: state,
        event: event,
        index: index,
        inputs: inputs,
        trace: &log.(:trace, &1),
        debug: &log.(:debug, &1),
        info: &log.(:info, &1),
        warn: &log.(:warn, &1),
        error: &log.(:error, &1),
        put: &Flex2.ObservableMap.put(pid, &1, &2)
      }
    end

    try do
      Process.put(:__state__, %{})
      loop(fun, ctx, inputs, %{}, index, :mount)
    rescue
      error in RuntimeError ->
        Log.error("fun:#{index} rescue: #{Log.inspect?(error.message)}")

      error ->
        Log.error("fun:#{index} rescue: #{Log.inspect?(error)}")
    catch
      error -> Log.error("fun:#{index} catch: #{Log.inspect?(error)}")
    end

    event = Process.get(:__event__)
    state = Process.get(:__state__)
    inputs = Process.get(:__input__)
    ctx = [event: event, inputs: inputs, state: state]
    Log.error("fun:#{index} #{Log.inspect?(ctx)}")
  end

  defp loop(fun, ctx, inputs, state, index, event) do
    Process.put(:__event__, event)
    Process.put(:__input__, inputs)
    state = safe(fun, ctx.(inputs, state, event), index, state)
    Process.put(:__state__, state)

    receive do
      {:timer, arg, ms} ->
        Process.send_after(self(), {:timer, arg, ms}, ms)
        inputs = Map.update(inputs, arg, 1, &(&1 + 1))
        loop(fun, ctx, inputs, state, index, {:timer, arg})

      {{Flex2.ObservableMap, _name, _point}, arg, val} ->
        inputs = Map.put(inputs, arg, val)
        loop(fun, ctx, inputs, state, index, {:point, arg})

      unexpected ->
        # single fun crash kills the whole flow logic
        throw(unexpected: unexpected)
    end
  end

  defp safe(fun, ctx = %{event: event}, index, state) do
    try do
      fun.(ctx)
    rescue
      error in RuntimeError ->
        Log.error("fun:#{index} #{Log.inspect?(event)} rescue: #{Log.inspect?(error.message)}")
        state

      error ->
        Log.error("fun:#{index} #{Log.inspect?(event)} rescue: #{Log.inspect?(error)}")
        state
    catch
      error ->
        Log.error("fun:#{index} #{Log.inspect?(event)} catch: #{Log.inspect?(error)}")
        state
    end
  end

  defp check(name, value, :fun) do
    case value do
      {fun, args} ->
        Setter.check("#{name}:fun", fun, {:fun, 1})
        Setter.check("#{name}:args", args, {:list, nil, &check(&1, &2, :arg)})

      _ ->
        Setter.abort(name, value, "invalid fun")
    end
  end

  defp check(name, value, :arg) do
    case value do
      {key, value} ->
        Setter.check(name, key, :atom)

        case value do
          {:timer, value} -> Setter.check("#{name}:timer", value, {:integer, 1, 65_535})
          {:point, value} -> Setter.check("#{name}:point", value, :binary)
          {:const, _value} -> :ok
          _ -> Setter.abort(name, value, "invalid arg")
        end

      _ ->
        Setter.abort(name, value, "invalid arg")
    end
  end
end
