use Terminal.Live

index = for item <- items, do: item.name
items = for(item <- items, do: {item.name, item}) |> Enum.into(%{})

box? = true
zstep = 1.2

new = %{
  items: %{},
  props: %{
    w: 800,
    h: 600,
    snap: 10,
    grid: true,
    style: """
    background-color: black;
    """
  }
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
# frame:fit -> updates screen fit and resets vp view -> recalculates

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

calc = fn state = %{screen: %{props: %{w: sw, h: sh}}, vp: vp} ->
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
  state, :init, screen ->
    state = Map.put(state, :screen, screen)
    state = Map.put(state, :vp, vp)
    state

  state = %{vp: %{frame: nil}}, :resize, {fw, fh} ->
    state = put_in(state, [:vp, :frame], %{w: fw, h: fh})
    state |> clean.() |> calc.()

  state = %{vp: %{frame: nil}}, _, _ ->
    state

  state = %{screen: %{props: %{w: sw, h: sh}}, vp: vp}, :resize, {fw, fh} ->
    %{s: vs, x: vx, y: vy, fit: fit, port: %{s: ps}} = vp
    vw = vs * sw
    vh = vs * sh
    %{s: ns} = port.(fit, fw, fh, vw, vh)
    df = ns / ps
    x = df * vx
    y = df * vy
    state = Map.put(state, :vp, %{vp | frame: %{w: fw, h: fh}, x: x, y: y})
    state |> clean.() |> calc.()

  state = %{vp: %{fit: fit, frame: frame}}, :fit, nil ->
    state = Map.put(state, :vp, %{vp | frame: frame, fit: fit})
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

size = fn
  0, 0 -> ""
  0, h -> "height: #{h}px;"
  w, 0 -> "width: #{w}px;"
  w, h -> "width: #{w}px; height: #{h}px;"
end

option = fn assigns ->
  assigns = ui.phxattr.(assigns)

  ~H"""
  <div
  {@phxattr}
  class={[
    "flex items-center gap-1 text-nowrap",
    "text-white hover:text-lime-500",
    ]}>
    {render_slot(@inner_block)}
  </div>
  """
end

menu = fn assigns ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :option, option)
  assigns = Map.put(assigns, :index, index)

  ~H"""
  <div
  id={@id}
  {@phxattr}
  style={"left: #{@x}px; top: #{@y}px;"}
  class={[
    "absolute flex flex-col p-2 bg-black",
    "border border-1 border-solid border-white rounded-lg",
    ]}>
    <div :if={@items} class="flex flex-col">
      <.fui :for={item <- @index} fun={@option} phx-click="item:add"
        phx-value-x={@x} phx-value-y={@y}
        phx-value-type={item}>Add {item}</.fui>
      <hr class="border-t border-white my-1"/>
    </div>
    <.fui fun={@option} phx-click="frame:fit" phx-value-fit="All">Fit All</.fui>
    <.fui fun={@option} phx-click="frame:fit" phx-value-fit="Auto">Fit Auto</.fui>
    <.fui fun={@option} phx-click="frame:fit" phx-value-fit="Width">Fit Width</.fui>
    <.fui fun={@option} phx-click="frame:fit" phx-value-fit="Height">Fit Height</.fui>
  </div>
  """
end

item = fn assigns ->
  assigns = Map.put(assigns, :size, size)
  assigns = Map.put(assigns, :pass, Map.take(assigns, [:x, :y, :rt, :props, :size, :runtime]))
  assigns = Map.put(assigns, :fun, items[assigns.type].render)

  ~H"""
  <.fui fun={@fun} id={"item_#{@id}_#{@type}"} {@pass} class={
    ["absolute", @selected && "outline outline-solid outline-2 outline-offset-2 outline-lime-500"]}/>
  """
end

form = fn assigns ->
  assigns = ui.phxattr.(assigns)

  ~H"""
    <form id={@id} class={[@class, "[&_*]:text-xs"]} {@phxattr} autocomplete="off">
      <input type="submit" hidden>
      <input type="hidden" name="iid" value={@iid}/>
      <.fui fun={@editor} item={@item} rt={@rt}/>
    </form>
  """
end

editor = fn assigns = %{item: item} ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :ui, ui)
  assigns = Map.put(assigns, :props, item.props)
  assigns = Map.put(assigns, :errors, item.errors)

  ~H"""
  <div>Size WxH</div>
  <div class="grid grid-cols-2 gap-1">
    <.fui fun={@ui.input} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
    <.fui fun={@ui.input} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
  </div>
  <div>Grid Visible</div>
  <.fui fun={@ui.select} name="grid" value={"\t#{@props.grid}"} error={@errors.grid} values={["\ttrue", "\tfalse"]}/>
  <div>Grid Snap</div>
  <.fui fun={@ui.input} name="snap" value={@props.snap} error={@errors.snap} type="number" step="1"/>
  <div class="col-span-2">Style</div>
  <div class="col-span-2">
    <.fui fun={@ui.area} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
  </div>
  """
end

# _target only preset for change events
# empty and out of range inputs are acceptable for change events
# validation is only guaranteed in submit events
save = fn state = %{selected: %{item: sitem}, screen: aitem = %{props: props}}, id, params ->
  Api.debug(id: id, params: params)

  change = %{errors: vlib.errors.(props)}
  params = vlib.params.(props, params)

  change = vlib.parse.(change, props, params, :w, {:integer, 100, 3840})
  change = vlib.parse.(change, props, params, :h, {:integer, 100, 2160})
  change = vlib.parse.(change, props, params, :snap, {:integer, 1, 100})
  change = vlib.parse.(change, props, params, :grid, :boolean)
  change = vlib.parse.(change, props, params, :style, :style)

  props = Map.merge(props, Map.drop(change, [:errors]))
  aitem = Map.put(aitem, :props, props)
  state = Map.put(state, :screen, aitem)
  sitem = Map.put(sitem, :props, params)
  sitem = Map.put(sitem, :errors, change.errors)
  state = put_in(state, [:selected, :item], sitem)

  case Map.has_key?(change, :w) or Map.has_key?(change, :h) do
    true -> apply.(state, :fit, nil)
    false -> state
  end
end

props = fn
  type -> items[type].props
end

select = fn
  %{screen: screen = %{props: props}}, type, nil ->
    screen = Map.put(screen, :errors, vlib.errors.(props))
    %{id: "id", type: type, item: screen, editor: editor, save: save}

  %{screen: screen}, type, id ->
    item = %{props: props} = screen.items[id]
    item = Map.put(item, :errors, vlib.errors.(props))

    %{
      id: id,
      type: type,
      item: item,
      editor: items[type].editor,
      save: items[type].save
    }
end

{:ok, cubdb} = CubDB.start_link(data_dir: path)

save = fn %{id: id, screen: screen} ->
  CubDB.put(cubdb, id, screen)
  Api.putcast!("flex:user-screens:design:#{id}", screen)
end

load = fn id ->
  CubDB.get(cubdb, id) || new
end

handle = fn state, id, event ->
  rt = state.rts[id]
  item = state.screen.items[id]
  rt = items[item.type].handle.(item, rt, event)
  put_in(state, [:rts, id], rt)
end

# acceptable to end up with events: nil -> nil
init = fn state = %{events: events}, id, item, design? ->
  {rt, key} =
    items[item.type].init.(item, fn key ->
      case {design?, Map.has_key?(events, key)} do
        {false, true} -> Adb.get(key)
        {false, false} -> Api.subget!(key)
        _ -> item.props.default
      end
    end)

  list = events[key]
  list = if key, do: [id | list || []], else: list
  state = put_in(state, [:events, key], list)
  state = put_in(state, [:rts, id], rt)
  state
end

%{
  port: port,
  form: form,
  menu: menu,
  item: item,
  apply: apply,
  props: props,
  select: select,
  handle: handle,
  init: init,
  load: load,
  save: save
}
