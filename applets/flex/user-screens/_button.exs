defmodule Flex.UserScreens.Button do
  alias Flex.UserScreens.VUtils
  use Flex.Live

  @name "Button"

  @props %{
    w: 0,
    h: 30,
    text: @name,
    sink: "",
    default: "0",
    style: "",
    calc: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    # button supports disabled pseudo class, div does not
    # div supports both hover and active pseudo classes
    # moved to emulated button to support delete on backspace while disabled
    ~H"""
      <div id={@id} class={@class}
        phx-click={!@rt.disabled && @rt? && "item:click"}
        phx-value-id={!@rt.disabled && @rt? && @id}
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
    assigns = Map.put(assigns, :sinks, ["" | Pt.get_sinks()])

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Text</div>
    <.fui fun={&UI.input/1} name="text" value={@props.text} error={@errors.text} type="text"/>
    <div>Sink</div>
    <.fui fun={&UI.select/1} name="sink" value={@props.sink} error={@errors.sink} values={@sinks}/>
    <div>Default</div>
    <.fui fun={&UI.input/1} name="default" value={@props.default} error={@errors.default}/>
    <div class="col-span-2">Style</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
    </div>
    <div class="col-span-2">Calculator</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="calc" value={@props.calc} error={@errors.calc} rows="8" class="w-full"/>
    </div>
    <div class="col-span-2">Output</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} value={@rt.output} readonly rows="8" class="w-full"/>
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
    change = VUtils.parse(change, props, params, :sink, :text?)
    change = VUtils.parse(change, props, params, :default, {:point, params.sink})
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

  def calculate(%{props: props}, value) do
    %{style: style, calc: calc, default: default, text: text, sink: sink} = props
    disabled = sink == ""
    bindings = [value: value, default: default, text: text, disabled: disabled]
    take = [:text, :disabled]
    {output, taken, style} = VUtils.eval_rt(calc, bindings, take, style)
    css = VUtils.parse_css(style)
    text = VUtils.get_typed(taken, :text, :binary)
    disabled = VUtils.get_typed(taken, :disabled, :boolean)
    %{css: css, output: output, text: text, disabled: disabled}
  end

  def handle(_item = %{props: %{sink: ""}}, rt, _event) do
    rt
  end

  def handle(%{props: %{sink: sink, default: default}}, rt, {:event, "item:click", _params}) do
    Pt.put_value("sink:#{sink}", default)
    rt
  end

  def handle(item, _rt, _event = {:point, _key, value}) do
    calculate(item, value)
  end

  def init(item = %{props: %{sink: ""}}, _design?, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item, _design? = true, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item = %{props: %{sink: sink}}, _design?, subget) do
    key = "sink:#{sink}"
    value = subget.(key)
    rt = calculate(item, value)
    {rt, key}
  end
end

:ok
