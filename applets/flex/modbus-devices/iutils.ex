defmodule Flex.ModbusDevices.IUtils do
  alias Flex.ModbusDevices.PUtils

  @new %{
    name: "Local Slave",
    proto: "TCP",
    port: 44001,
    ip: "127.0.0.1",
    status: :disabled,
    delay: 20,
    points: []
  }

  @protos ["TCP", "RTU"]
  @status [:disabled, :enabled]

  @options %{status: @status, protos: @protos}

  def merge(item), do: Map.merge(@new, item)

  def parse(params, points) do
    params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Map.update!(params, "port", &String.to_integer/1)
    params = Map.update!(params, "delay", &String.to_integer/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    Enum.into(params, %{points: points})
  end

  def values(points) do
    values =
      for {id, index} when is_binary(id) <- points do
        for {_, accessors} <- index do
          for %{key: key, get: get, put: put, parse: parse} <- accessors do
            {key, %{val: get.(), put: put, parse: parse}}
          end
        end
      end
      |> List.flatten()
      |> Enum.into(%{})

    points |> Enum.into(%{}) |> Map.put(:values, values)
  end

  def runtime(state, items) do
    state = Map.put(state, :index, index(items))
    state = Map.put(state, :points, points(items))
    state = Map.put(state, :items, Enum.into(items, %{}))
    state
  end

  def modal(args) do
    case args do
      {:capture, state, key, val, type, enc, tag} ->
        input = %{key: key, val: val, enc: enc}
        limits = PUtils.limits(%{type: type, encoding: enc})

        modal = %{
          title: "Capture Value for #{tag}",
          input: input,
          limits: limits,
          type: :capture
        }

        state = Map.put(state, :modal, modal)
        Map.put(state, :options, nil)

      {:points, state, id, item = %{points: points}} ->
        points = if length(points) > 0, do: points, else: [PUtils.new()]
        item = Map.put(item, :points, points)
        modal = %{title: "Edit Modbus Points", id: id, input: item, type: :points}
        state = Map.put(state, :modal, modal)
        Map.put(state, :options, PUtils.options())

      {:item, state, id, item} ->
        modal = %{title: "Edit Modbus Device", id: id, input: item, type: :item}
        state = Map.put(state, :modal, modal)
        Map.put(state, :options, @options)

      {:item, state} ->
        modal = %{title: "Add Modbus Device", id: nil, input: @new, type: :item}
        state = Map.put(state, :modal, modal)
        Map.put(state, :options, @options)

      {:paste, state} ->
        modal = %{title: "Paste Modbus Device", type: :paste}
        Map.put(state, :modal, modal)
    end
  end

  defp index(pairs) do
    Enum.map(pairs, fn {k, _} -> k end)
  end

  defp points(items) do
    for {id, %{points: points}} <- items do
      {id,
       for point <- points do
         {point, PUtils.accessors(point)}
       end}
    end
    |> values()
  end
end

:ok
