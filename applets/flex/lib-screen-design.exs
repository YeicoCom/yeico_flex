use Terminal.Live

new = %{
  fit: "All",
  port: %{x: 0, y: 0, width: 800, height: 600},
  size: %{width: 800, height: 600}
}

fit = fn type, size, view ->
  mr =
    case type do
      "All" -> min(size.width / view.width, size.height / view.height)
      "Width" -> size.width / view.width
      "Height" -> size.height / view.height
    end

  w = mr * view.width
  h = mr * view.height
  x = (size.width - w) / 2
  y = (size.height - h) / 2
  %{x: x, y: y, width: w, height: h}
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
  </div>
  """
end

item = fn assigns ->
  assigns = phx_attribs.(assigns)
  assigns = Map.put_new(assigns, :id, nil)

  ~H"""
  <div
  id={@id}
  {@phx_attribs}
  class={[]}>{render_slot(@inner_block)}</div>
  """
end

%{
  new: new,
  fit: fit,
  menu: menu,
  item: item
}
