use Terminal.Live

new = %{
  fit: "All",
  items: [
    %{x: 0, y: 100, w: 800, h: 10},
    %{x: 100, y: 0, w: 10, h: 600}
  ],
  port: %{x: 0, y: 0, w: 800, h: 600},
  size: %{w: 800, h: 600}
}

fit = fn
  {type, frame, port} ->
    s =
      case type do
        "All" -> min(frame.w / port.w, frame.h / port.h)
        "Width" -> frame.w / port.w
        "Height" -> frame.h / port.h
      end

    w = s * port.w
    h = s * port.h
    x = (frame.w - w) / 2
    y = (frame.h - h) / 2
    %{s: s, x: x, y: y, w: w, h: h}

  {port = %{x: x, y: y}, %{w: w, h: h}} ->
    s = port.w / w
    %{s: s, x: -x, y: -y, w: w, h: h}
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
  new: new,
  fit: fit,
  menu: menu,
  item: item
}
