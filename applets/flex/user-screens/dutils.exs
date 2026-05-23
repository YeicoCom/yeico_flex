defmodule Flex.UserScreens.DUtils do
  alias Flex.UserScreens.Label
  alias Flex.UserScreens.Button
  alias Flex.UserScreens.Link
  alias Flex.UserScreens.Image
  alias Flex.UserScreens.Capture
  alias Flex.UserScreens.Display
  alias Flex.UserScreens.VUtils
  use Flex.Live

  @modules [Label, Button, Capture, Image, Link, Display]
  @index for(m <- @modules, do: m.name())
  @items for(m <- @modules, do: {m.name(), m}) |> Enum.into(%{})

  @box? true
  @zstep 1.2

  @new %{
    items: %{},
    props: %{
      w: 800,
      h: 600,
      snap: 10,
      grid: true,
      style: """
      background-color: #232323;
      border-radius: 4px;
      """
    }
  }

  @vp %{
    x: 0,
    y: 0,
    s: 1,
    dx: 0,
    dy: 0,
    fit: "All",
    frame: nil,
    port: nil,
    panel: nil
  }

  # frame:resize -> updates frame w,h -> recalculates
  # frame:fit -> updates screen fit and resets vp view -> recalculates

  def port(fit, fw, fh, vw, vh, rt? \\ false) do
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
    y = if(rt?, do: (fh - h) / 2, else: 0)
    %{s: s, x: x, y: y, w: w, h: h}
  end

  def calc_layout(state, :init, screen) do
    state = Map.put(state, :screen, screen)
    state = Map.put(state, :vp, @vp)
    state
  end

  def calc_layout(state = %{vp: %{frame: nil}}, :resize, {fw, fh}) do
    state = put_in(state, [:vp, :frame], %{w: fw, h: fh})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: %{frame: nil}}, _, _) do
    state
  end

  def calc_layout(state = %{screen: %{props: %{w: sw, h: sh}}, vp: vp}, :resize, {fw, fh}) do
    %{s: vs, x: vx, y: vy, fit: fit, port: %{s: ps}} = vp
    vw = vs * sw
    vh = vs * sh
    %{s: ns} = port(fit, fw, fh, vw, vh)
    df = ns / ps
    x = df * vx
    y = df * vy
    state = Map.put(state, :vp, %{vp | frame: %{w: fw, h: fh}, x: x, y: y})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: %{fit: fit, frame: frame}}, :fit, nil) do
    state = Map.put(state, :vp, %{@vp | frame: frame, fit: fit})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: %{frame: frame}}, :fit, fit) do
    state = Map.put(state, :vp, %{@vp | frame: frame, fit: fit})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: vp}, :wheel, {x, y, _dx, dy}) do
    %{s: vs, x: vx, y: vy, panel: %{x: px, y: py}} = vp
    sf = if dy > 0, do: @zstep, else: if(dy < 0, do: 1 / @zstep, else: 1)
    sf = if @box?, do: max(min(sf, 1 / vs), 0.1 / vs), else: sf
    df = 1 - 1 / sf
    dx = df * (x - px)
    dy = df * (y - py)
    state = Map.put(state, :vp, %{vp | s: sf * vs, x: vx + dx, y: vy + dy})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: vp = %{x: x, y: y}}, :drag, {mx, my, ox, oy, "up", moved?}) do
    x = x + if moved?, do: mx - ox, else: 0
    y = y + if moved?, do: my - oy, else: 0
    state = Map.put(state, :vp, %{vp | x: x, y: y})
    state |> clean() |> calc()
  end

  def calc_layout(state = %{vp: vp}, :drag, {mx, my, ox, oy, _event, _moved?}) do
    dx = mx - ox
    dy = my - oy
    state = Map.put(state, :vp, %{vp | dx: dx, dy: dy})
    state |> calc()
  end

  def menu(assigns) do
    assigns = UI.phxattr(assigns)
    assigns = Map.put(assigns, :option, &option/1)
    assigns = Map.put(assigns, :index, @index)

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

  def item(assigns) do
    assigns = Map.put(assigns, :size, &size/2)
    assigns = Map.put(assigns, :pass, Map.take(assigns, [:x, :y, :rt, :props, :size, :rt?]))
    assigns = Map.put(assigns, :fun, Function.capture(@items[assigns.type], :render, 1))

    ~H"""
    <.fui fun={@fun} id={"item_#{@id}_#{@type}"} {@pass} class={["item-base", "item-#{@type}", @selected && "item-selected"]}/>
    """
  end

  def form(assigns) do
    assigns = UI.phxattr(assigns)

    ~H"""
      <form id={@id} class={@class} {@phxattr} autocomplete="off">
        <input type="submit" hidden>
        <.fui fun={@selected.editor} id={@selected.id} item={@selected.item} rt={@rt}/>
      </form>
    """
  end

  def props(type), do: @items[type].props()

  def select(%{screen: screen = %{props: props}}, type, nil) do
    screen = Map.put(screen, :errors, VUtils.errors(props))
    %{id: nil, type: type, item: screen, editor: &editor/1, save: &save/3}
  end

  def select(%{screen: screen}, type, id) do
    item = %{props: props} = screen.items[id]
    item = Map.put(item, :errors, VUtils.errors(props))

    %{
      id: id,
      type: type,
      item: item,
      editor: Function.capture(@items[type], :editor, 1),
      save: Function.capture(@items[type], :save, 3)
    }
  end

  def snap(x, y, %{props: %{snap: snap, w: w, h: h}}) do
    x = div(round(x), snap) * snap
    y = div(round(y), snap) * snap
    # w/h optional: one pixel to witness out of bounds controls
    x = min(max(x, 0), w - 1)
    y = min(max(y, 0), h - 1)
    {x, y}
  end

  def save_screen(ddb, %{id: id, screen: screen}, force?) do
    if force? || Adb.get("flex:user-screens:item:#{id}") do
      prev = Db.get(ddb, id)
      diff = prev != screen

      if diff do
        Db.put(ddb, id, screen)
        Bus.broadcast!("flex:user-screens:design:#{id}", screen)
      end
    end
  end

  def load_screen(ddb, id) do
    Db.get(ddb, id) || @new
  end

  def subget_screen(ddb, id) do
    Bus.subscribe!("flex:user-screens:design:#{id}", nil)
    Db.get(ddb, id) || @new
  end

  def handle(state, id, {:modal, "item:modal", params}) do
    rt = state.rts[id]
    item = state.screen.items[id]
    {rt, modal} = @items[item.type].modal(id, item, rt, params)
    state = put_in(state, [:rts, id], rt)
    Map.put(state, :modal, modal)
  end

  def handle(state, id, {:submit, "submit:modal", params}) do
    rt = state.rts[id]
    item = state.screen.items[id]
    modal = state.modal
    {rt, modal} = @items[item.type].submit(id, item, rt, params, modal)
    state = put_in(state, [:rts, id], rt)
    Map.put(state, :modal, modal)
  end

  def handle(state, id, event) do
    rt = state.rts[id]
    item = state.screen.items[id]
    rt = @items[item.type].handle(item, rt, event)
    put_in(state, [:rts, id], rt)
  end

  # acceptable to end up with events: nil -> []
  def init(state = %{events: events}, id, item, design?) do
    {rt, key} =
      @items[item.type].init(item, design?, fn key ->
        case Map.has_key?(events, key) do
          # nil initial values allow the use of || in calculator
          false -> Pt.subget_value(key)
          true -> Pt.get_value(key)
        end
      end)

    list = events[key] || []
    list = if key, do: [id | list], else: list
    state = put_in(state, [:events, key], list)
    state = put_in(state, [:rts, id], rt)
    state
  end

  def remove(state, id) do
    {_, state} = pop_in(state, [:rts, id])
    {_, state} = pop_in(state, [:screen, :items, id])
    state = Map.put(state, :selected, select(state, "Screen", nil))
    state = Map.put(state, :menu, nil)
    state
  end

  def max(%{screen: %{items: items}}) do
    case map_size(items) do
      0 ->
        0

      _ ->
        items
        |> Enum.map(fn {_, item} -> item.index end)
        |> Enum.max()
    end
  end

  defp size(0, 0), do: ""
  defp size(0, h), do: "height: #{h}px;"
  defp size(w, 0), do: "width: #{w}px;"
  defp size(w, h), do: "width: #{w}px; height: #{h}px;"

  defp calc(state = %{screen: %{props: %{w: sw, h: sh}}, vp: vp}) do
    %{s: vs, x: vx, y: vy, dx: dx, dy: dy, fit: fit, frame: %{w: fw, h: fh}} = vp
    px = vx + dx
    py = vy + dy
    vw = vs * sw
    vh = vs * sh

    state =
      put_in(state, [:vp, :port], %{s: ps, w: pw, h: ph} = port(fit, fw, fh, vw, vh))

    px = if @box?, do: max(min(px, 0), pw - sw * ps), else: px
    py = if @box?, do: max(min(py, 0), ph - sh * ps), else: py
    state = put_in(state, [:vp, :panel], %{s: ps, x: px, y: py, w: sw, h: sh})
    # boxing back propagation (harmless when not boxing)
    state = put_in(state, [:vp, :x], px - dx)
    state = put_in(state, [:vp, :y], py - dy)
    state
  end

  defp clean(state) do
    state = put_in(state, [:vp, :dx], 0)
    state = put_in(state, [:vp, :dy], 0)
    state
  end

  defp option(assigns) do
    assigns = UI.phxattr(assigns)

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

  defp editor(assigns = %{item: item}) do
    assigns = UI.phxattr(assigns)
    assigns = Map.put(assigns, :props, item.props)
    assigns = Map.put(assigns, :errors, item.errors)

    ~H"""
    <div>Size WxH</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Grid Visible</div>
    <.fui fun={&UI.select/1} name="grid" value={"\t#{@props.grid}"} error={@errors.grid} values={["\ttrue", "\tfalse"]}/>
    <div>Grid Snap</div>
    <.fui fun={&UI.input/1} name="snap" value={@props.snap} error={@errors.snap} type="number" step="1"/>
    <div class="col-span-2">Style</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
    </div>
    """
  end

  # _target only present in change events
  # empty and out of range inputs are acceptable for change events
  # client side form validation is only guaranteed in submit events
  defp save(state = %{selected: %{item: sitem}, screen: aitem = %{props: props}}, _id, params) do
    change = %{errors: VUtils.errors(props)}
    params = VUtils.params(props, params)

    change = VUtils.parse(change, props, params, :w, {:integer, 100, 3840})
    change = VUtils.parse(change, props, params, :h, {:integer, 100, 2160})
    change = VUtils.parse(change, props, params, :snap, {:integer, 1, 100})
    change = VUtils.parse(change, props, params, :grid, :boolean)
    change = VUtils.parse(change, props, params, :style, :style)

    props = Map.merge(props, Map.drop(change, [:errors]))
    aitem = Map.put(aitem, :props, props)
    state = Map.put(state, :screen, aitem)
    sitem = Map.put(sitem, :props, props)
    sitem = Map.put(sitem, :errors, change.errors)
    state = put_in(state, [:selected, :item], sitem)

    case Map.has_key?(change, :w) or Map.has_key?(change, :h) do
      true -> calc_layout(state, :fit, nil)
      false -> state
    end
  end
end

:ok
