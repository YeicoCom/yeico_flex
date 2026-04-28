use Terminal.Live

name = "Label"

props = %{text: name}

render = fn assigns ->
  assigns = Map.put(assigns, :ui, ui)

  ~H"""
    <div id={@id} class={[
      "absolute",
      @selected && "border border-2 border-lime-500",
      "bg-red-500 text-white py-2 px-4 rounded",
      ]}
      style={["left: #{@x}px; top: #{@y}px;", @size.(@w, @h)]}>
      {@props.text}
    </div>
  """
end

editor = fn assigns ->
  assigns = ui.phxattr.(assigns)
  assigns = Map.put(assigns, :ui, ui)

  ~H"""
  <div>Size</div>
  <div class="grid grid-cols-2 py-1 gap-1">
    <.fui fun={@ui.input} name="w" value={@item.w} type="number" step="1" min="0" max="3840" title="0-3840" required/>
    <.fui fun={@ui.input} name="h" value={@item.h} type="number" step="1" min="0" max="2160" title="0-2160" required/>
  </div>
  <div>Text</div>
  <.fui fun={@ui.input} name="text" value={@item.props.text} type="text" pattern="[a-zA-Z0-9]+" required/>
  """
end

save = fn state, id, params ->
  Api.debug(id: id, params: params)
  state
end

%{
  name: name,
  props: props,
  render: render,
  editor: editor,
  save: save
}
