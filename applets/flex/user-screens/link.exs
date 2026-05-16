defmodule Flex.UserScreens.Link do
  alias Flex.UserScreens.VUtils
  use Flex.Live

  @name "Link"

  @props %{
    w: 0,
    h: 0,
    text: @name,
    screen: "",
    style: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    # https://www.erlang.org/doc/apps/stdlib/io_lib.html#format/2
    # search: io_lib Format Escapes

    ~H"""
      <a id={@id} class={[@class,
        "text-lime-600",
        "active:text-lime-400",
        "hover:text-lime-500",
        "data-[disabled]:text-zinc-600",
        ]}
        data-disabled={@rt.disabled}
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
    assigns = Map.put(assigns, :screens, ["" | Pt.get_screens()])
    assigns = Map.put(assigns, :inspect?, &VUtils.inspect?/1)

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Text</div>
    <.fui fun={&UI.input/1} name="text" value={@props.text} error={@errors.text} type="text"/>
    <div>Screen</div>
    <.fui fun={&UI.select/1} name="screen" value={@props.screen} error={@errors.screen} values={@screens}/>
    <div class="col-span-2">Style</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="style" value={@props.style} error={@errors.style} rows="8" class="w-full"/>
    </div>
    """
  end

  def calculate(%{props: %{style: style, text: text, screen: screen}}, _value) do
    css = VUtils.get_css(style)
    [href | _] = String.split(screen, ":", parts: 2)
    disabled = href == ""
    %{css: css, text: text, disabled: disabled, href: if(disabled, do: nil, else: href)}
  end

  def save(state = %{selected: %{item: sitem}, screen: screen}, id, params) do
    # Log.debug(id: id, params: params)

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
    sitem = Map.put(sitem, :props, params)
    sitem = Map.put(sitem, :errors, change.errors)
    state = put_in(state, [:selected, :item], sitem)
    state = put_in(state, [:rts, id], calculate(aitem, nil))
    state
  end

  def handle(_, rt, _) do
    rt
  end

  def init(item, _) do
    rt = calculate(item, nil)
    {rt, nil}
  end
end

:ok
