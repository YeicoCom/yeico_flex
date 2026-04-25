use Terminal.Live

new = %{
  id: nil,
  name: nil,
  items: [
    %{x: 0, y: 100, w: 800, h: 10},
    %{x: 100, y: 0, w: 10, h: 600}
  ],
  size: %{w: 800, h: 600}
}

vp = %{
  fit: "All",
  x: 0,
  y: 0,
  s: 1.0,
  frame: nil,
  port: nil,
  panel: nil
}

# frame:resize -> updates frame w,h -> recalculates
# cmd:fit -> updates screen fit and resets vp view -> recalculates

port = fn fit, fw, fh, vw, vh ->
  s =
    case fit do
      "All" -> min(fw / vw, fh / vh)
      "Width" -> fw / vw
      "Height" -> fh / vh
    end

  w = s * vw
  h = s * vh
  x = (fw - w) / 2
  y = (fh - h) / 2
  %{s: s, x: x, y: y, w: w, h: h}
end

calc = fn state = %{screen: %{size: %{w: sw, h: sh}}, vp: vp} ->
  %{fit: fit, s: vs, frame: %{w: fw, h: fh}} = vp
  vw = vs * sw
  vh = vs * sh
  state = put_in(state, [:vp, :port], %{s: s} = port.(fit, fw, fh, vw, vh))
  state = put_in(state, [:vp, :panel], %{s: s, x: 0, y: 0, w: vw, h: vh})
  state
end

apply = fn
  state, :init, _ ->
    state = Map.put(state, :screen, new)
    state = Map.put(state, :vp, vp)
    state

  state = %{vp: %{frame: nil}}, :fit, fit ->
    state = Map.put(state, :vp, %{vp | fit: fit})
    state

  state = %{vp: %{frame: frame}}, :fit, fit ->
    state = Map.put(state, :vp, %{vp | frame: frame, fit: fit})
    calc.(state)

  state, :resize, {fw, fh} ->
    state = put_in(state, [:vp, :frame], %{w: fw, h: fh})
    calc.(state)

  state = %{vp: vp = %{s: s, x: vx, y: vy}}, :wheel, {x, y, _dx, dy} ->
    sf = if dy > 0, do: 1.1, else: if(dy < 0, do: 1 / 1.1, else: 1)
    state = Map.put(state, :vp, %{vp | s: sf * s, x: vx, y: vy})
    calc.(state)
end

phx_attribs = fn assigns ->
  Map.put_new(
    assigns,
    :phx_attribs,
    for {k, v} <- assigns, reduce: %{} do
      acc ->
        case {String.starts_with?("#{k}", "phx-"), String.starts_with?("#{k}", "data-")} do
          {true, _} -> Map.put(acc, k, v)
          {_, true} -> Map.put(acc, k, v)
          _ -> acc
        end
    end
  )
end

option = fn assigns ->
  assigns = phx_attribs.(assigns)

  ~H"""
  <div
  {@phx_attribs}
  class={[
    "flex items-center gap-1 select-none text-nowrap text-white cursor-default",
    "hover:cursor-pointer hover:text-lime-500",
    ]}>
    {render_slot(@inner_block)}
  </div>
  """
end

menu = fn assigns ->
  assigns = phx_attribs.(assigns)
  assigns = Map.put_new(assigns, :option, option)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :x, nil)
  assigns = Map.put_new(assigns, :y, nil)

  ~H"""
  <div
  id={@id}
  {@phx_attribs}
  style={"left: #{@x}px; top: #{@y}px;"}
  class={[
    "absolute flex flex-col p-2 bg-black",
    "border border-1 border-solid border-white rounded-lg",
    ]}>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="All">Fit All</.fui>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Width">Fit Width</.fui>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Height">Fit Height</.fui>
    <.fui fun={@option} phx-click="cmd:add">Add Item</.fui>
  </div>
  """
end

item = fn assigns ->
  assigns = phx_attribs.(assigns)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :x, nil)
  assigns = Map.put_new(assigns, :y, nil)
  assigns = Map.put_new(assigns, :w, nil)
  assigns = Map.put_new(assigns, :h, nil)

  ~H"""
  <div
  id={@id}
  {@phx_attribs}
  style={"left: #{@x}px; top: #{@y}px;width: #{@w}px;height: #{@h}px;"}
  class={[
    "absolute bg-red-500",
    ]}/>
  """
end

%{
  apply: apply,
  menu: menu,
  item: item
}
