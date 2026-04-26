use Terminal.Live

box? = true
zstep = 1.2

new = %{
  id: nil,
  name: nil,
  items: [
    # %{x: 10, y: 10, w: 800 - 20, h: 600 - 20, bg: "white"},
    %{x: 0, y: 100, w: 800, h: 10, bg: "red"},
    %{x: 100, y: 0, w: 10, h: 600, bg: "red"}
  ],
  size: %{w: 800, h: 600}
}

vp = %{
  x: 0,
  y: 0,
  s: 1,
  dx: 0,
  dy: 0,
  fit: "Auto",
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
      "Auto" -> max(fw / vw, fh / vh)
      "Width" -> fw / vw
      "Height" -> fh / vh
    end

  w = min(fw, s * vw)
  h = min(fh, s * vh)
  x = (fw - w) / 2
  y = (fh - h) / 2
  %{s: s, x: x, y: y, w: w, h: h}
end

calc = fn state = %{screen: %{size: %{w: sw, h: sh}}, vp: vp} ->
  %{s: vs, x: vx, y: vy, dx: dx, dy: dy, fit: fit, frame: %{w: fw, h: fh}} = vp
  px = vx + dx
  py = vy + dy
  vw = vs * sw
  vh = vs * sh
  state = put_in(state, [:vp, :port], %{s: ps, w: pw, h: ph} = port.(fit, fw, fh, vw, vh))
  px = if box?, do: max(min(px, 0), pw - sw * ps), else: px
  py = if box?, do: max(min(py, 0), ph - sh * ps), else: py
  state = put_in(state, [:vp, :panel], %{s: ps, x: px, y: py, w: sw, h: sh})
  # boxing back propagation (harmless when not boxing)
  state = put_in(state, [:vp, :x], px - dx)
  state = put_in(state, [:vp, :y], py - dy)
  state
end

clean = fn state ->
  state = put_in(state, [:vp, :dx], 0)
  state = put_in(state, [:vp, :dy], 0)
  state
end

apply = fn
  state, :init, _ ->
    state = Map.put(state, :screen, new)
    state = Map.put(state, :vp, vp)
    state

  state = %{vp: %{frame: nil}}, :resize, {fw, fh} ->
    state = put_in(state, [:vp, :frame], %{w: fw, h: fh})
    state |> clean.() |> calc.()

  state = %{vp: %{frame: nil}}, _, _ ->
    state

  state = %{screen: %{size: %{w: sw, h: sh}}, vp: vp}, :resize, {fw, fh} ->
    %{s: vs, x: vx, y: vy, fit: fit, port: %{s: ps}} = vp
    vw = vs * sw
    vh = vs * sh
    %{s: ns} = port.(fit, fw, fh, vw, vh)
    df = ns / ps
    x = df * vx
    y = df * vy
    state = Map.put(state, :vp, %{vp | frame: %{w: fw, h: fh}, x: x, y: y})
    state |> clean.() |> calc.()

  state = %{vp: %{frame: frame}}, :fit, fit ->
    state = Map.put(state, :vp, %{vp | frame: frame, fit: fit})
    state |> clean.() |> calc.()

  state = %{vp: vp}, :wheel, {x, y, _dx, dy} ->
    %{s: vs, x: vx, y: vy, panel: %{x: px, y: py}} = vp
    sf = if dy > 0, do: zstep, else: if(dy < 0, do: 1 / zstep, else: 1)
    sf = if box?, do: min(sf, 1 / vs), else: sf
    df = 1 - 1 / sf
    dx = df * (x - px)
    dy = df * (y - py)
    state = Map.put(state, :vp, %{vp | s: sf * vs, x: vx + dx, y: vy + dy})
    state |> clean.() |> calc.()

  state = %{vp: vp = %{x: x, y: y}}, :drag, {mx, my, ox, oy, "up", moved?} ->
    x = x + if moved?, do: mx - ox, else: 0
    y = y + if moved?, do: my - oy, else: 0
    state = Map.put(state, :vp, %{vp | x: x, y: y})
    state |> clean.() |> calc.()

  state = %{vp: vp}, :drag, {mx, my, ox, oy, _event, _moved?} ->
    dx = mx - ox
    dy = my - oy
    state = Map.put(state, :vp, %{vp | dx: dx, dy: dy})
    state |> calc.()
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
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Auto">Fit Auto</.fui>
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
  assigns = Map.put_new(assigns, :bg, nil)

  ~H"""
  <div
  id={@id}
  {@phx_attribs}
  style={"left: #{@x}px; top: #{@y}px;width: #{@w}px;height: #{@h}px;background-color: #{@bg};"}
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
