defmodule Flex.UserScreens.Label do
  alias Flex.UserScreens.VUtils
  use Flex.Use.Live

  @name "Label"

  @props %{
    w: 0,
    h: 30,
    text: @name,
    type: "source",
    point: "",
    default: "0",
    style: "",
    calc: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    ~H"""
      <div id={@id} class={@class}
        disabled={@rt.disabled}
        tabindex="-1"
        style={[
          "left: #{@x}px; top: #{@y}px;",
          @size.(@props.w, @props.h),
        ]}>
        {@rt.text}
      </div>
      <style id={"#{@id}_Style"}>
      <%= "\##{@id}" %> { <%= @rt.css[nil] %> }
      <%= "\##{@id}:hover" %> { <%= @rt.css["hover"] %> }
      <%= "\##{@id}:active" %> { <%= @rt.css["active"] %> }
      <%= "\##{@id}[disabled]" %> { <%= @rt.css["disabled"] %> }
      </style>
    """
  end

  def editor(assigns = %{item: item}) do
    assigns = UI.phxattr(assigns)
    assigns = Map.put(assigns, :props, item.props)
    assigns = Map.put(assigns, :errors, item.errors)
    points = if item.props.type == "source", do: Points.get_sources(), else: Points.get_sinks()
    assigns = Map.put(assigns, :points, ["" | points])

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Text</div>
    <.fui fun={&UI.input/1} name="text" value={@props.text} error={@errors.text} type="text"/>
    <div>Type</div>
    <.fui fun={&UI.select/1} name="type" value={@props.type} error={@errors.type} values={["source", "sink"]}/>
    <div>Point</div>
    <.fui fun={&UI.select/1} name="point" value={@props.point} error={@errors.point} values={@points}/>
    <div>Default</div>
    <.fui fun={&UI.input/1} name="default" value={@props.default} error={@errors.default}/>
    <div class="col-span-2">Style</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="style" value={@props.style} error={@errors.style} rows="6" class="w-full"/>
    </div>
    <div class="col-span-2">Calculator</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="calc" value={@props.calc} error={@errors.calc} rows="6" class="w-full"/>
    </div>
    <div class="col-span-2">Output</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} value={@rt.output} readonly rows="6" class="w-full"/>
    </div>
    """
  end

  def save(state = %{selected: %{item: sitem}, screen: screen}, id, params) do
    %{items: items, props: %{w: w, h: h}} = screen
    aitem = %{props: props} = items[id]
    change = %{errors: VUtils.errors(props)}
    params = VUtils.params(props, params)

    change = VUtils.parse(change, props, params, :w, {:integer, 0, w})
    change = VUtils.parse(change, props, params, :h, {:integer, 0, h})
    change = VUtils.parse(change, props, params, :text, :text?)
    change = VUtils.parse(change, props, params, :type, :text?)
    change = VUtils.parse(change, props, params, :point, :text?)
    change = VUtils.parse(change, props, params, :default, {:point, params.point})
    change = VUtils.parse(change, props, params, :style, :style)
    change = VUtils.parse(change, props, params, :calc, :text?)

    props = Map.merge(props, Map.drop(change, [:errors]))
    aitem = Map.put(aitem, :props, props)
    state = put_in(state, [:screen, :items, id], aitem)
    sitem = Map.put(sitem, :props, props)
    sitem = Map.put(sitem, :errors, change.errors)
    state = put_in(state, [:selected, :item], sitem)
    state = put_in(state, [:rts, id], calculate(aitem, nil))
    state
  end

  def calculate(%{props: %{style: style, calc: calc, default: default, text: text}}, value) do
    bindings = [value: value, default: default, text: text, disabled: false]
    take = [:text, :disabled]
    {output, taken, style} = VUtils.eval_rt(calc, bindings, take, style)
    css = VUtils.parse_css(style)
    text = VUtils.get_typed(taken, :text, :binary)
    disabled = VUtils.get_typed(taken, :disabled, :boolean)
    %{css: css, output: output, text: text, disabled: disabled}
  end

  def handle(%{props: %{point: ""}}, rt, _) do
    rt
  end

  def handle(item, _rt, _event = {:point, _key, value}) do
    calculate(item, value)
  end

  def init(item = %{props: %{point: ""}}, _design?, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item, _design? = true, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item = %{props: %{type: type, point: point}}, _design?, subget) do
    key = "#{type}:#{point}"
    value = subget.(key)
    rt = calculate(item, value)
    {rt, key}
  end
end
