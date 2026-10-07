defmodule Flex.ReactiveLogic do
  use Flex.Service
  use Terminal

  defp initial(),
    do: %{
      id: nil,
      funs: []
    }

  defp checks(),
    do: %{
      id: :binary,
      funs: {:list, nil, &check(&1, &2, :fun)}
    }

  def add(config = %{funs: funs}, fun, args \\ []) do
    Check.check("fun", fun, {:fun, 1})
    Check.check("args", args, {:list, nil, &check(&1, &2, :arg)})
    funs = [{fun, args} | funs] |> Enum.reverse()
    Map.put(config, :funs, funs)
  end

  defp name(%{id: id}),
    do: "reactive-logic:#{id}"

  defp setup(config = %{funs: funs}) do
    sid = name(config)
    Log.debug("#{sid} run")

    for {{fun, args}, index} <- funs |> Enum.with_index() do
      tag = "#{sid}:fun:#{index}"
      async = fn -> setup(sid, index, fun, args) end
      Api.async(async, tag: tag)
    end

    Api.receive()
    exit(:kill)
  end

  defp setup(sid, index, fun, args) do
    fid = "#{sid}:fun:#{index}"

    log = fn level, term ->
      Api.log(level, "#{fid} #{Api.inspect?(term)}")
    end

    ctx =
      %{
        fid: fid,
        state: %{},
        index: index,
        event: :mount,
        inputs: init(index, args),
        trace: &log.(:trace, &1),
        debug: &log.(:debug, &1),
        info: &log.(:info, &1),
        warn: &log.(:warn, &1),
        error: &log.(:error, &1),
        put: &Api.putcast!(&1, &2)
      }

    {:error, %{error: error}} = Api.safe(fn -> loop(fun, ctx) end)
    Log.warn("#{fid} #{Api.inspect?(Process.get(:__environ__))} #{Api.inspect?(error)}")
  end

  defp loop(fun, ctx = %{index: index, event: event, inputs: inputs, state: state}) do
    Process.put(:__environ__, event: event, inputs: inputs, state: state)
    state = fun.(ctx)
    ctx = Map.merge(ctx, %{state: state})
    Process.put(:__environ__, event: event, inputs: inputs, state: state)

    receive do
      {:timer, {^index, arg}, ms} ->
        Process.send_after(self(), {:timer, {index, arg}, ms}, ms)
        inputs = Map.update(inputs, arg, 1, &(&1 + 1))
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:timer, arg}})
        loop(fun, ctx)

      {point, {^index, arg}, val} when is_binary(point) ->
        inputs = Map.put(inputs, arg, val)
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:point, arg}})
        loop(fun, ctx)

      unexpected ->
        # single fun crash kills the whole flow logic
        throw(unexpected: unexpected)
    end
  end

  defp init(index, args) do
    for {arg, spec} <- args, reduce: %{} do
      inputs ->
        case spec do
          {:const, const} ->
            Map.put(inputs, arg, const)

          {:point, point} ->
            val = Api.subget!(point, sarg: {index, arg}, defv: nil)
            Map.put(inputs, arg, val)

          {:timer, ms} ->
            Process.send_after(self(), {:timer, {index, arg}, ms}, ms)
            Map.put(inputs, arg, 0)
        end
    end
  end

  defp check(name, value, :fun) do
    case value do
      {fun, args} ->
        Check.check("#{name}:fun", fun, {:fun, 1})
        Check.check("#{name}:args", args, {:list, nil, &check(&1, &2, :arg)})

      _ ->
        Check.abort(name, value, "invalid fun")
    end
  end

  defp check(name, value, :arg) do
    case value do
      {key, value} ->
        Check.check(name, key, :atom)

        case value do
          {:timer, value} -> Check.check("#{name}:timer", value, {:integer, 1, 65_535})
          {:point, value} -> Check.check("#{name}:point", value, :binary)
          {:const, _value} -> :ok
          _ -> Check.abort(name, value, "invalid arg")
        end

      _ ->
        Check.abort(name, value, "invalid arg")
    end
  end
end
