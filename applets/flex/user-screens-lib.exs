use Terminal

name = "User Screen"

shift = fn tzoffset, logs ->
  logs
  |> Enum.map(fn {k, log = %{dt: dt}} ->
    dt = NaiveDateTime.shift(dt, hour: tzoffset)
    dt = NaiveDateTime.to_time(dt)
    {k, %{log | dt: dt}}
  end)
  |> Enum.into(%{})
end

new = %{
  name: name,
  status: :disabled
}

status = [:disabled, :enabled]
options = %{status: status}

modal = fn
  {:edit, state, id, item} ->
    Map.put(state, :modal, %{
      title: "Edit #{name}",
      item: item,
      id: id,
      opts: options
    })

  {:add, state} ->
    Map.put(state, :modal, %{
      title: "Add #{name}",
      item: new,
      id: nil,
      opts: options
    })
end

index = fn pairs -> Enum.map(pairs, fn {k, _} -> k end) end

apply = fn item, action ->
  case action do
    "enable" -> Map.put(item, :status, :enabled)
    "disable" -> Map.put(item, :status, :disabled)
  end
end

parse = fn params ->
  params = Map.update!(params, "status", &String.to_atom/1)
  params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
  Enum.into(params, %{})
end

%{
  modal: modal,
  shift: shift,
  parse: parse,
  apply: apply,
  index: index
}
