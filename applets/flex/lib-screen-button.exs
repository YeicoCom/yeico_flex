use Terminal.Live

name = "Button"

props = %{
  w: 0,
  h: 0,
  text: name,
  sink: "",
  default: 0,
  style: """
  color: white;
  font-size: 16px;
  padding: 2px 16px;
  border-radius: 4px;
  text-align: center;
  background-color: blue;
  """,
  calc: """
  %{disabled: value == default}
  """
}

render = fn assigns ->
  ~H"""
    <div id={@id} class={@class}
      phx-click={@runtime && "item:click"}
      phx-value-id={@runtime && @id}
      style={[
        "left: #{@x}px; top: #{@y}px;",
        @size.(@props.w, @props.h),
        @props.style
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
  assigns = Map.put(assigns, :sinks, ["" | wlib.sinks.()])

  ~H"""
  <div>Size</div>
  <div class="grid grid-cols-2 gap-1">
    <.fui fun={@ui.input} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
    <.fui fun={@ui.input} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
  </div>
  <div>Text</div>
  <.fui fun={@ui.input} name="text" value={@props.text} error={@errors.text} type="text"/>
  <div>Sink</div>
  <.fui fun={@ui.select} name="sink" value={@props.sink} error={@errors.sink} values={@sinks}/>
  <div>Default</div>
  <.fui fun={@ui.input} name="default" value={@props.default} error={@errors.default}/>
  <div class="col-span-2">Style</div>
  <div class="col-span-2">
    <.fui fun={@ui.area} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
  </div>
  <div class="col-span-2">Calculator</div>
  <div class="col-span-2">
    <.fui fun={@ui.area} name="calc" value={@props.calc} error={@errors.calc} rows="8" class="w-full"/>
  </div>
  <div class="col-span-2">Output</div>
  <div class="col-span-2">
    <.fui fun={@ui.area} value={inspect(@rt.error || @rt.calc)} disabled rows="8" class="w-full"/>
  </div>
  """
end

calculate = fn %{props: props}, value ->
  {error, calc} =
    case Api.safe(fn -> Code.eval_string(props.calc, default: props.default, value: value) end) do
      {:ok, {res, _}} when is_map(res) -> {nil, res}
      {:ok, {res, _}} -> {res, %{}}
      {:error, error} -> {error, %{}}
    end

  %{calc: calc, error: error}
end

save = fn state = %{selected: %{item: sitem}, screen: screen}, id, params ->
  Api.debug(id: id, params: params)

  %{items: items, props: %{w: w, h: h}} = screen
  aitem = %{props: props} = items[id]
  change = %{errors: vlib.errors.(props)}
  params = vlib.params.(props, params)

  change = vlib.parse.(change, props, params, :w, {:integer, 0, w})
  change = vlib.parse.(change, props, params, :h, {:integer, 0, h})
  change = vlib.parse.(change, props, params, :text, :text)
  change = vlib.parse.(change, props, params, :sink, :any)
  change = vlib.parse.(change, props, params, :default, {:point, params.sink})
  change = vlib.parse.(change, props, params, :style, :style)
  change = vlib.parse.(change, props, params, :calc, :any)

  props = Map.merge(props, Map.drop(change, [:errors]))
  aitem = Map.put(aitem, :props, props)
  state = put_in(state, [:screen, :items, id], aitem)
  sitem = Map.put(sitem, :props, params)
  sitem = Map.put(sitem, :errors, change.errors)
  state = put_in(state, [:selected, :item], sitem)
  state = put_in(state, [:rts, id], calculate.(aitem, nil))
  state
end

handle = fn
  %{props: %{sink: ""}}, rt, _ ->
    rt

  %{props: %{sink: sink, default: default}}, rt, "item:click" ->
    Api.putcast!("flex:point:sink:#{sink}", default)
    rt

  item, _, {"flex:point:" <> _, value} ->
    calculate.(item, value)
end

init = fn
  item = %{props: %{sink: ""}}, _ ->
    rt = calculate.(item, nil)
    {rt, nil}

  item = %{props: %{sink: sink}}, subget! ->
    key = "flex:point:sink:#{sink}"
    value = subget!.(key)
    rt = calculate.(item, value)
    {rt, key}
end

%{
  name: name,
  props: props,
  render: render,
  editor: editor,
  handle: handle,
  init: init,
  save: save
}
