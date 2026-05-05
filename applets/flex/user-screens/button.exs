use Terminal.Live

name = "Button"

props = %{
  w: 0,
  h: 0,
  text: name,
  sink: "",
  default: "0",
  style: "",
  calc: ""
}

render = fn assigns ->
  # button supports disabled pseudo class, div does not
  # div supports both hover and active pseudo classes
  ~H"""
    <button id={@id} class={[@class, "px-4 py-2 rounded",
      "bg-blue-600 active:bg-blue-400 hover:bg-blue-500",
      "disabled:bg-zinc-600 disabled:text-zinc-400"]}
      disabled={@rt.disabled}
      phx-click={!@rt.disabled && @runtime && "item:click"}
      phx-value-id={!@rt.disabled && @runtime && @id}
      style={[
        "left: #{@x}px; top: #{@y}px;",
        @size.(@props.w, @props.h),
      ]}>
      {@rt.text}
    </button>
    <style id={"#{@id}_Style"}>
    <%= "\##{@id}" %> { <%= @rt.css[nil] %> }
    <%= "\##{@id}:hover" %> { <%= @rt.css["hover"] %> }
    <%= "\##{@id}:active" %> { <%= @rt.css["active"] %> }
    <%= "\##{@id}:disabled" %> { <%= @rt.css["disabled"] %> }
    </style>
  """
end

editor = fn assigns = %{item: item} ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :ui, ui)
  assigns = Map.put(assigns, :props, item.props)
  assigns = Map.put(assigns, :errors, item.errors)
  assigns = Map.put(assigns, :sinks, ["" | pt.get_sinks.()])
  assigns = Map.put(assigns, :inspect?, vutils.inspect?)

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
    <.fui fun={@ui.area} value={@inspect?.(@rt.output)} readonly rows="8" class="w-full"/>
  </div>
  """
end

calculate = fn %{props: %{style: style, calc: calc, default: default, text: text}}, value ->
  bindings = [value: value, default: default, text: text]
  take = [:text, :disabled, :style]
  {output, calc, style} = vutils.eval.(calc, bindings, take, style)
  css = vutils.css.(style)
  text = vutils.get.(calc, :text, :binary) || text
  disabled = vutils.get.(calc, :disabled, :boolean) || false
  %{css: css, output: output, text: text, disabled: disabled}
end

save = fn state = %{selected: %{item: sitem}, screen: screen}, id, params ->
  # Api.debug(id: id, params: params)

  %{items: items, props: %{w: w, h: h}} = screen
  aitem = %{props: props} = items[id]
  change = %{errors: vutils.errors.(props)}
  params = vutils.params.(props, params)

  change = vutils.parse.(change, props, params, :w, {:integer, 0, w})
  change = vutils.parse.(change, props, params, :h, {:integer, 0, h})
  change = vutils.parse.(change, props, params, :text, :text)
  change = vutils.parse.(change, props, params, :sink, :text?)
  change = vutils.parse.(change, props, params, :default, {:point, params.sink})
  change = vutils.parse.(change, props, params, :style, :style)
  change = vutils.parse.(change, props, params, :calc, :text?)

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
    pt.put_value.("sink:#{sink}", default)
    rt

  item, _, {_, value} ->
    calculate.(item, value)
end

init = fn
  item = %{props: %{sink: ""}}, _ ->
    rt = calculate.(item, nil)
    {rt, nil}

  item = %{props: %{sink: sink}}, subget! ->
    key = "sink:#{sink}"
    value = subget!.(key)
    rt = calculate.(item, value)
    {rt, key}
end

:ok
