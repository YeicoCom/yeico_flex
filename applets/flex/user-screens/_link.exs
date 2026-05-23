defmodule Flex.UserScreens.Link do
  alias Flex.UserScreens.VUtils
  use Flex.Live

  @name "Link"

  @props %{
    w: 0,
    h: 30,
    text: @name,
    screen: "",
    style: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    ~H"""
      <a id={@id} class={@class}
        disabled={@rt.disabled}
        tabindex="-1"
        style={[
          "left: #{@x}px; top: #{@y}px;",
          @size.(@props.w, @props.h),
        ]} href={@rt.href} draggable="false">
        {@rt.text}
      </a>
      <style id={"#{@id}_Style"}>
      <%= "\##{@id}" %> { <%= @rt.css[nil] %> }
      <%= "\##{@id}:hover" %> { <%= @rt.css["hover"] %> }
      <%= "\##{@id}:active" %> { <%= @rt.css["active"] %> }
      <%= "\##{@id}:disabled" %> { <%= @rt.css["disabled"] %> }
      </style>
    """
  end

  def editor(assigns = %{item: item}) do
    assigns = UI.phxattr(assigns)
    assigns = Map.put(assigns, :props, item.props)
    assigns = Map.put(assigns, :errors, item.errors)
    assigns = Map.put(assigns, :screens, [{"", ""} | Pt.get_screens()])

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Text</div>
    <.fui fun={&UI.input/1} name="text" value={@props.text} error={@errors.text} type="text"/>
    <div>Screen</div>
    <.fui fun={&UI.select/1} name="screen" value={@props.screen} error={@errors.screen} values2={@screens}/>
    <div class="col-span-2">Style</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="style" value={@props.style} error={@errors.style} rows="6" class="w-full"/>
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
    change = VUtils.parse(change, props, params, :screen, :text?)
    change = VUtils.parse(change, props, params, :style, :style)

    props = Map.merge(props, Map.drop(change, [:errors]))
    aitem = Map.put(aitem, :props, props)
    state = put_in(state, [:screen, :items, id], aitem)
    sitem = Map.put(sitem, :props, props)
    sitem = Map.put(sitem, :errors, change.errors)
    state = put_in(state, [:selected, :item], sitem)
    state = put_in(state, [:rts, id], calculate(aitem, nil))
    state
  end

  def calculate(%{props: %{style: style, text: text, screen: screen}}, value) do
    css = VUtils.parse_css(style)

    value =
      case {screen, value} do
        {"", _} -> nil
        {_, nil} -> Pt.get_value("screen:#{screen}")
        _ -> value
      end

    disabled = !value
    %{css: css, text: text, disabled: disabled, href: if(disabled, do: nil, else: value)}
  end

  def handle(item, _rt, _event = {:point, _key, value}) do
    calculate(item, value)
  end

  def init(item = %{props: %{screen: ""}}, _design?, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item, _design? = true, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item = %{props: %{screen: screen}}, _design?, subget) do
    key = "screen:#{screen}"
    value = subget.(key)
    rt = calculate(item, value)
    {rt, key}
  end
end

:ok
