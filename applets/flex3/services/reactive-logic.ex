defmodule Flex.ReactiveLogic do
  use Flex.Service
  use Terminal

  # Confirmed that script defined functions log and stacktrace
  # accurately without explicit wrapper (due to async wrapper)

  # Adb is the global transient state
  # reactors share global state through Api.putcast!
  # valid sources are:
  #   {const_name, {:const, fixed_value}}
  #   {point_name, {:point, adb_point_key}}
  #   {timer_name, {:timer, period_in_ms}}
  #   {shared_name, {:shared, shared_key}}

  defp specs(),
    do: %{
      id: %{initial: nil, check: :binary},
      shared: %{initial: %{}, check: :map},
      reactors: %{initial: [], check: {:list, nil, &Flex.Reactor.check(&1, &2)}}
    }

  def add(config = %{reactors: reactors}, mod, opts \\ []) when is_atom(mod) and is_list(opts) do
    reactors = [reactors, {mod, mod.new(opts)}] |> List.flatten()
    %{config | reactors: reactors}
  end

  defp name(%{id: id}),
    do: "reactive-logic:#{id}"

  defp setup(config = %{reactors: reactors, shared: shared}) do
    sid = name(config)
    Log.debug("#{sid} run")

    for {{mod, config}, index} <- reactors |> Enum.with_index() do
      tag = "#{sid}:reactor:#{index}"
      %{handler: handler, inputs: inputs} = mod.build(config)
      async = fn -> setup(tag, index, handler, inputs, shared) end
      Api.async(async, tag: tag)
    end

    Api.receive()
    exit(:kill)
  end

  defp setup(rid, index, handler, inputs, shared) do
    ctx =
      %{
        rid: rid,
        state: %{},
        index: index,
        event: :mount,
        inputs: init(index, inputs, shared)
      }

    {:error, error} = Api.safe(fn -> first(handler, ctx) end)
    %{error: error, type: type, stack: stack} = error
    environ = Process.get(:__environ__)
    msg = "#{rid} #{type} #{Api.inspect?(error)}"

    # expect inaccurate file in stacktraces for script defined functions
    Log.warn(
      [msg, Api.inspect?(environ) | stack]
      |> Enum.map(&Api.inspect?/1)
      |> Enum.join("\n\t")
    )
  end

  defp first(handler, ctx = %{event: event, inputs: inputs, state: state}) do
    Process.put(:__environ__, event: event, inputs: inputs, state: state)
    loop(handler, ctx)
  end

  defp loop(handler, ctx = %{index: index, event: event, inputs: inputs}) do
    state = handler.(ctx)
    ctx = Map.merge(ctx, %{state: state})
    Process.put(:__environ__, event: event, inputs: inputs, state: state)

    receive do
      {:timer, ^index, name, ms} ->
        Process.send_after(self(), {:timer, index, name, ms}, ms)
        inputs = Map.update(inputs, name, 1, &(&1 + 1))
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:timer, name}})
        loop(handler, ctx)

      {_point, {:point, ^index, name}, val} ->
        inputs = Map.put(inputs, name, val)
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:point, name}})
        loop(handler, ctx)

      unexpected ->
        # single handler crash kills the whole service
        throw(unexpected: unexpected)
    end
  end

  def init(index, inputs, shared) do
    for {name, spec} <- inputs, into: %{} do
      case spec do
        {:const, const} ->
          {name, const}

        {:point, point} ->
          {name, Api.subget!(point, sarg: {:point, index, name}, defv: nil)}

        {:timer, ms} ->
          Process.send_after(self(), {:timer, index, name, ms}, ms)
          {name, 0}

        {:shared, key} ->
          {name, shared[key]}
      end
    end
  end
end
