defmodule Flex.UserScreens.Display do
  alias Flex.UserScreens.VUtils
  use Flex.Live

  @name "Display"

  @props %{
    w: 0,
    h: 0,
    source: "",
    default: "0",
    heex: "<div>Display</div>",
    calc: ""
  }

  def name, do: @name
  def props, do: @props

  def render(assigns) do
    ~H"""
      <div id={@id} class={[@class]}
        tabindex="-1"
        style={[
          "left: #{@x}px; top: #{@y}px;",
          @size.(@props.w, @props.h),
        ]}>
        <%= if @rt.error? do %>
        <div style="width: 10px;height: 10px;background-color: red;"/>
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
    assigns = Map.put(assigns, :sources, ["" | Pt.get_sources()])

    ~H"""
    <div>Size</div>
    <div class="grid grid-cols-2 gap-1">
      <.fui fun={&UI.input/1} name="w" value={@props.w} error={@errors.w} type="number" step="1"/>
      <.fui fun={&UI.input/1} name="h" value={@props.h} error={@errors.h} type="number" step="1"/>
    </div>
    <div>Source</div>
    <.fui fun={&UI.select/1} name="source" value={@props.source} error={@errors.source} values={@sources}/>
    <div>Default</div>
    <.fui fun={&UI.input/1} name="default" value={@props.default} error={@errors.default}/>
    <div class="col-span-2">Heex</div>
    <div class="col-span-2">
      <.fui fun={&UI.area/1} name="heex" value={@props.heex} error={@errors.heex} rows="8" class="w-full"/>
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
    change = VUtils.parse(change, props, params, :source, :text?)
    change = VUtils.parse(change, props, params, :default, {:point, params.source})
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

  def calculate(%{props: %{heex: heex, calc: calc, default: default, source: source}}, value) do
    bindings = [value: value, default: default]
    {output, calculated} = VUtils.eval_calc(calc, bindings)
    source? = source != ""
    assigns = Map.new(calculated)
    assigns = Map.put_new(assigns, :value, value)
    assigns = Map.put_new(assigns, :default, default)
    assigns = Map.put(assigns, :source?, source?)

    render = fn ->
      opts = [
        caller: __ENV__,
        source: "display.heex",
        engine: Phoenix.LiveView.TagEngine,
        tag_handler: Phoenix.LiveView.HTMLEngine
      ]

      # ast = EEx.compile_string(heex, opts)
      # {content, _bindings} = Code.eval_quoted(ast, assigns: assigns)
      # content
      EEx.eval_string(heex, [assigns: assigns], opts)
      |> Phoenix.HTML.Engine.encode_to_iodata!()
    end

    {error?, inner} =
      case Api.safe(render) do
        {:ok, content} -> {false, fn _, _ -> {:safe, content} end}
        {:error, _} -> {true, fn _, _ -> {:safe, ""} end}
      end

    %{output: output, source?: source?, error?: error?, content: [%{inner_block: inner}]}
  end

  def handle(%{props: %{source: ""}}, rt, _) do
    rt
  end

  def handle(item, _rt, _event = {:point, _key, value}) do
    calculate(item, value)
  end

  def init(item = %{props: %{source: ""}}, _design?, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item, _design? = true, _subget) do
    rt = calculate(item, nil)
    {rt, nil}
  end

  def init(item = %{props: %{source: source}}, _design?, subget) do
    key = "source:#{source}"
    value = subget.(key)
    rt = calculate(item, value)
    {rt, key}
  end
end

:ok
