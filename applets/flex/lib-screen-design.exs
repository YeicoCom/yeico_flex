use Terminal.Live

box? = true
zstep = 1.2

new = %{
  id: nil,
  name: nil,
  items: %{},
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
    sf = if box?, do: max(min(sf, 1 / vs), 0.1 / vs), else: sf
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
    "hover:text-lime-500",
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
  assigns = Map.put_new(assigns, :items, nil)

  ~H"""
  <div
  id={@id}
  {@phx_attribs}
  style={"left: #{@x}px; top: #{@y}px;"}
  class={[
    "absolute flex flex-col p-2 bg-black",
    "border border-1 border-solid border-white rounded-lg",
    ]}>
    <div :if={@items} class="flex flex-col">
      <.fui fun={@option} phx-click="cmd:add" phx-value-x={@x} phx-value-y={@y} phx-value-type="Button">Add Button</.fui>
      <.fui fun={@option} phx-click="cmd:add" phx-value-x={@x} phx-value-y={@y} phx-value-type="Label">Add Label</.fui>
      <hr class="border-t border-white my-1"/>
    </div>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="All">Fit All</.fui>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Auto">Fit Auto</.fui>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Width">Fit Width</.fui>
    <.fui fun={@option} phx-click="cmd:fit" phx-value-fit="Height">Fit Height</.fui>
  </div>
  """
end

button = fn assigns ->
  ~H"""
    <div id={@id} class={[
      @design && "absolute cursor-default",
      @design && "hover:border hover:border-2 hover:border-lime-500",
      "bg-blue-500 text-white py-2 px-4 rounded",
      ]}
      style={"left: #{@x}px; top: #{@y}px;"}>
      {@type}
    </div>
  """
end

label = fn assigns ->
  ~H"""
    <div id={@id} class={[
      @design && "absolute cursor-default",
      @design && "hover:border hover:border-2 hover:border-lime-500",
      "bg-red-500 text-white py-2 px-4 rounded",
      ]}
      style={"left: #{@x}px; top: #{@y}px;"}>
      {@type}
    </div>
  """
end

# cursor-default to remove safari text cursor
item = fn assigns ->
  assigns = Map.put(assigns, :pass, Map.take(assigns, [:x, :y, :type, :props]))

  assigns =
    case assigns.type do
      "Button" -> Map.put(assigns, :fun, button)
      "Label" -> Map.put(assigns, :fun, label)
    end

  ~H"""
  <.fui fun={@fun} id={"item_#{@id}_#{@type}"} design={true} {@pass}/>
  """
end

get = fn
  "Screen", _ -> fn state, _, key -> get_in(state, [:screen, key]) end
  _, _ -> fn state, id, key -> get_in(state, [:screen, :items, id, :props, key]) end
end

put = fn
  "Screen", _ -> fn state, _, key, val -> put_in(state, [:screen, key], val) end
  _, _ -> fn state, id, key, val -> put_in(state, [:screen, :items, id, :props, key], val) end
end

select = fn type, id ->
  %{type: type, id: id, get: get.(type, id), put: put.(type, id)}
end

%{
  new: new,
  menu: menu,
  item: item,
  apply: apply,
  select: select
}
