defmodule Flex.UserScreens.Display do
  alias Flex.UserScreens.VUtils
  use Flex.Use.Live

  @name "Display"

  @props %{
    w: 0,
    h: 0,
    type: "source",
    point: "",
    default: "0",
    heex: "<div>Display</div>\n<style>\n@scope {div {color: green;}}\n</style>",
    calc: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    ~H"""
      <div id={@id} class={@class}
        tabindex="-1"
        style={[
          "left: #{@x}px; top: #{@y}px;",
          @size.(@props.w, @props.h),
        ]}>
        <%= if @rt.error? do %>
        <div style="width: 10px; height: 10px; background-color: red;"/>
        <% else %>
        {render_slot(@rt.content)}
        <% end %>
      </div>
    """
  end

  def editor(assigns = %{item: item}) do
    assigns = UI.phxattr(assigns)
    assigns = Map.put(assigns, :props, item.props)
    assigns = Map.put(assigns, :errors, item.errors)
    points = if item.props.type == "source", do: Pt.get_sources(), else: Pt.get_sinks()
    assigns = Map.put(assigns, :points, ["" | points])

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Type</div>
    <.fui fun={&UI.select/1} name="type" value={@props.type} error={@errors.type} values={["source", "sink"]}/>
    <div>Point</div>
    <.fui fun={&UI.select/1} name="point" value={@props.point} error={@errors.point} values={@points}/>
    <div>Default</div>
    <.fui fun={&UI.input/1} name="default" value={@props.default} error={@errors.default}/>
    <div class="col-span-2">Template</div>
    <div class="col-span-2">
      <.fui fun={&UI.code/1} name="heex" value={@props.heex} error={@errors.heex}
        class="w-full h-[16em]" id={"#{@id}_heex"} lang="markup"/>
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
    change = VUtils.parse(change, props, params, :type, :text?)
    change = VUtils.parse(change, props, params, :point, :text?)
    change = VUtils.parse(change, props, params, :default, {:point, params.point})
    change = VUtils.parse(change, props, params, :heex, :text?)
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

  def calculate(
        %{props: %{heex: heex, calc: calc, default: default, point: point}},
        value,
        ast \\ nil
      ) do
    bindings = [value: value, default: default]
    {error, calculated} = VUtils.eval_calc(calc, bindings)
    point? = point != ""
    assigns = Map.new(calculated)
    assigns = Map.put(assigns, :point?, point?)

    render = fn ->
      opts = [
        caller: __ENV__,
        source: "display.heex",
        engine: Phoenix.LiveView.TagEngine,
        tag_handler: Phoenix.LiveView.HTMLEngine
      ]

      ast = ast || EEx.compile_string(heex, opts)
      {content, _bindings} = Code.eval_quoted(ast, assigns: assigns)
      {ast, Phoenix.HTML.Engine.encode_to_iodata!(content)}
    end

    {error?, ast, inner} =
      case Api.safe(render) do
        {:ok, {ast, content}} -> {false, ast, fn _, _ -> {:safe, content} end}
        {:error, _} -> {true, ast, fn _, _ -> {:safe, ""} end}
      end

    %{
      ast: ast,
      error?: error?,
      point?: point?,
      content: [%{inner_block: inner}],
      output: error || VUtils.pretty_vars(calculated)
    }
  end

  def handle(%{props: %{point: ""}}, rt, _) do
    rt
  end

  def handle(item, rt, _event = {:point, _key, value}) do
    calculate(item, value, rt[:ast])
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

:ok
