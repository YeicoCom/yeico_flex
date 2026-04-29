use Terminal.Live

name = "Button"

props = %{
  w: 0,
  h: 0,
  text: name,
  color: "#2563eb"
}

render = fn assigns ->
  assigns = Map.put(assigns, :ui, ui)

  ~H"""
    <div id={@id} class={[
      "absolute",
      @selected && "border border-2 border-lime-500",
      "text-white py-2 px-4 rounded",
      ]}
      style={[
        "left: #{@x}px; top: #{@y}px;",
        @size.(@props.w, @props.h),
        "background-color: #{@props.color};"
      ]}>
      {@props.text}
    </div>
  """
end

editor = fn assigns = %{item: item} ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :ui, ui)
  assigns = Map.put(assigns, :props, item.props)
  assigns = Map.put(assigns, :errors, item.errors)

  ~H"""
  <div>Size</div>
  <div class="grid grid-cols-2 py-1 gap-1">
    <.fui fun={@ui.input} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
    <.fui fun={@ui.input} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
  </div>
  <div>Color</div>
  <div class="grid grid-cols-2 py-1 gap-1">
    <.fui fun={@ui.input} name="color" value={@props.color} error={@errors.color} type="text"/>
    <div style={"background-color: #{@props.color};"} class="rounded-lg"/><div/>
  </div>
  <div>Text</div>
  <.fui fun={@ui.input} name="text" value={@props.text} error={@errors.text} type="text"/>
  """
end

save = fn state = %{selected: %{item: sitem}, screen: screen}, id, params ->
  Api.debug(id: id, params: params)

  %{items: items, props: %{w: w, h: h}} = screen
  aitem = %{props: props} = items[id]
  change = %{errors: val.errors.(props)}
  params = val.params.(props, params)

  change = val.parse.(change, props, params, :w, {:int, 0, w})
  change = val.parse.(change, props, params, :h, {:int, 0, h})
  change = val.parse.(change, props, params, :color, :color)
  change = val.parse.(change, props, params, :text, :txt)

  props = Map.merge(props, Map.drop(change, [:errors]))
  aitem = Map.put(aitem, :props, props)
  state = put_in(state, [:screen, :items, id], aitem)
  sitem = Map.put(sitem, :props, params)
  sitem = Map.put(sitem, :errors, change.errors)
  state = put_in(state, [:selected, :item], sitem)
  state
end

%{
  name: name,
  props: props,
  render: render,
  editor: editor,
  save: save
}
