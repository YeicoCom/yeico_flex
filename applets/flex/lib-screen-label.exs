use Terminal.Live

name = "Label"

props = %{
  w: 0,
  h: 0,
  text: name,
  source: "",
  default: "0",
  style: """
  color: white;
  font-size: 16px;
  text-align: left;
  padding: 0px 0px;
  background-color: transparent;
  """,
  calc: """
  # bindings: value, default, text
  %{text: f.("Label ~s", default)}
  """
}

render = fn assigns ->
  # https://www.erlang.org/doc/apps/stdlib/io_lib.html#format/2
  # search: io_lib Format Escapes

  ~H"""
    <div id={@id} class={@class} disabled={@rt.disabled}
      style={[
        "left: #{@x}px; top: #{@y}px;",
        @size.(@props.w, @props.h),
      ]}>
      {@rt.text}
    </div>
    <style id={"#{@id}_Style"}>
    <%= "\##{@id}" %> { <%= @rt.css[nil] %> }
    <%= "\##{@id}[disabled]" %> { <%= @rt.css["disabled"] %> }
    </style>
  """
end

editor = fn assigns = %{item: item} ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :ui, ui)
  assigns = Map.put(assigns, :props, item.props)
  assigns = Map.put(assigns, :errors, item.errors)
  assigns = Map.put(assigns, :sources, ["" | wlib.sources.()])

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
    <.fui fun={@ui.area} value={inspect(@rt.output)} disabled rows="8" class="w-full"/>
  </div>
  """
end

calculate = fn %{props: %{style: style, calc: calc, default: default, text: text}}, value ->
  bindings = [value: value, default: default, text: text] ++ vlib.binds.()

  # no clean way to use error || calc
  {output, calc} =
    case Api.safe(fn -> Code.eval_string(calc, bindings) end) do
      {:ok, {_, kw}} -> {Keyword.take(kw, [:text, :disabled]), Enum.into(kw, %{})}
      {:error, error} -> {error, %{}}
    end

  css = vlib.css.(style)
  text = vlib.get.(calc, :text, :binary) || text
  disabled = vlib.get.(calc, :disabled, :boolean) || false
  %{css: css, output: output, text: text, disabled: disabled}
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
  change = vlib.parse.(change, props, params, :source, :any)
  change = vlib.parse.(change, props, params, :default, {:point, params.source})
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
  %{props: %{source: ""}}, rt, _ ->
    rt

  item, _, {"flex:point:" <> _, value} ->
    calculate.(item, value)
end

init = fn
  item = %{props: %{source: ""}}, _ ->
    rt = calculate.(item, nil)
    {rt, nil}

  item = %{props: %{source: source}}, subget! ->
    key = "flex:point:source:#{source}"
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
