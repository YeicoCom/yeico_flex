use Terminal

new = %{
  name: "Local Slave",
  proto: "TCP",
  port: 44001,
  ip: "127.0.0.1",
  status: :disabled,
  delay: 20,
  points: []
}

protos = ["TCP", "RTU"]
status = [:disabled, :enabled]

options = %{status: status, protos: protos}

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

parse = fn params, points ->
  params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Map.update!(params, "port", &String.to_integer/1)
  params = Map.update!(params, "delay", &String.to_integer/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{points: points})
end

values = fn points ->
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

points = fn devices ->
  for {id, %{points: points}} <- devices do
    {id,
     for point <- points do
       {point, putils.accessors.(point)}
     end}
  end
  |> values.()
end

runtime = fn state, devices ->
  state = Map.put(state, :index, index.(devices))
  state = Map.put(state, :points, points.(devices))
  state = Map.put(state, :devices, Enum.into(devices, %{}))
  state
end

modal = fn
  {:capture, state, key, val, type, enc, tag} ->
    input = %{key: key, val: val, enc: enc}
    capture = putils.capture.(%{type: type, encoding: enc})
    modal = %{title: "Capture Value for #{tag}", input: input, capture: capture, type: :capture}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, nil)

  {:points, state, id, device = %{points: points}} ->
    options = putils.options
    points = if length(points) > 0, do: points, else: [putils.new]
    device = Map.put(device, :points, points)
    modal = %{title: "Edit Modbus Points", id: id, input: device, type: :points}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)

  {:device, state, id, device} ->
    modal = %{title: "Edit Modbus Device", id: id, input: device, type: :device}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)

  {:device, state} ->
    modal = %{title: "Add Modbus Device", id: nil, input: new, type: :device}
    state = Map.put(state, :modal, modal)
    Map.put(state, :options, options)

  {:paste, state} ->
    modal = %{title: "Paste Modbus Device", type: :paste}
    Map.put(state, :modal, modal)
end

:ok
