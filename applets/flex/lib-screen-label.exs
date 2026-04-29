use Terminal.Live

name = "Label"

props = %{
  w: 0,
  h: 0,
  text: name,
  source: "",
  value: 0,
  style: """
  color: white;
  font-size: 16px;
  text-align: left;
  """
}

render = fn assigns ->
  assigns = Map.put(assigns, :ui, ui)

  ~H"""
    <div id={@id} class={["absolute", @selected && @ui.outline]}
      style={[
        "left: #{@x}px; top: #{@y}px;",
        @size.(@props.w, @props.h),
        @props.style,
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

  sources =
    "flex:points:source"
    |> Mdb.lookup()
    |> Enum.map(fn {_, v} -> "#{v.type}:#{v.name}" end)

  assigns = Map.put(assigns, :sources, ["" | sources])

  ~H"""
  <div>Size</div>
  <div class="grid grid-cols-2 gap-1">
    <.fui fun={@ui.input} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
    <.fui fun={@ui.input} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
  </div>
  <div>Text</div>
  <.fui fun={@ui.input} name="text" value={@props.text} error={@errors.text} type="text"/>
  <div>Source</div>
  <.fui fun={@ui.select} name="source" value={@props.source} error={@errors.source} values={@sources}/>
  <div>Value</div>
  <.fui fun={@ui.input} name="value" value={@props.value} error={@errors.value}/>
  <div class="col-span-2">Style</div>
  <div class="col-span-2">
    <.fui fun={@ui.area} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
  </div>
  """
end

save = fn state = %{selected: %{item: sitem}, screen: screen}, id, params ->
  Api.debug(id: id, params: params)

  %{items: items, props: %{w: w, h: h}} = screen
  aitem = %{props: props} = items[id]
  change = %{errors: val.errors.(props)}
  params = val.params.(props, params)

  change = val.parse.(change, props, params, :w, {:integer, 0, w})
  change = val.parse.(change, props, params, :h, {:integer, 0, h})
  change = val.parse.(change, props, params, :text, :text)
  change = val.parse.(change, props, params, :source, :any)
  # change = val.parse.(change, props, params, :value, {:type, params.source})
  change = val.parse.(change, props, params, :style, :style)

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
