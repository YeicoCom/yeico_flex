use Terminal.Live

phx_attribs = fn assigns ->
  Map.put_new(
    assigns,
    :phx_attribs,
    for {k, v} <- assigns, reduce: %{} do
      acc ->
        case String.starts_with?("#{k}", "phx-") do
          true -> Map.put(acc, k, v)
          _ -> acc
        end
    end
  )
end

frame = fn assigns ->
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :title, "Flex")

  ~H"""
  <div id="main_frame" class="flex flex-col gap-4 p-4 h-screen" phx-window-keydown="modal:close" phx-key="Escape">
     <div class="flex gap-4 p-4 items-center bg-zinc-800 rounded">
      <div class="relative group text-white content-center">
        <button class="px-4 py-2 bg-zinc-500 rounded hover:bg-lime-500 hero-bars-3 size-10"></button>
        <div class="absolute top-3/4 hidden group-hover:block w-48 bg-zinc-700 rounded shadow-xl mt-1">
          <a href="/flex/serial-exports" class="block px-4 py-2 hover:bg-lime-500">Serial Exports</a>
          <a href="/flex/socket-terminal" class="block px-4 py-2 hover:bg-lime-500">Socket Terminal</a>
          <a href="/flex/modbus-master" class="block px-4 py-2 hover:bg-lime-500">Modbus Master</a>
        </div>
      </div>
      <div class="text-[2em] text-white">{@title}</div>
      <div class="flex-grow"></div>
      <image src="/applets/logo.svg" class="h-10"/>
    </div>
    <div class="flex flex-grow gap-4 text-base">
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end

modal = fn assigns ->
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :title, nil)
  assigns = Map.put_new(assigns, :close, "modal:close")

  ~H"""
  <div
    class={[
      "fixed top-0 left-0 z-50 w-screen h-screen",
      "bg-neutral-200/50"
    ]}
  >
    <div class="flex justify-center items-center h-screen">
      <div class={["p-8 rounded-md bg-neutral-800", @class]} phx-click-away={@close}>
        <div class="pb-2 gap-20 flex justify-between items-center text-gray-400">
          <div class="text-lg font-semibold">{@title}</div>
          <button
            type="button"
            title="Close"
            phx-click={@close}
            class="hover:bg-gray-600 hover:text-white rounded-lg w-8 h-8 inline-flex justify-center items-center"
          >
            <span class="hero-x-mark-solid" />
          </button>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
  </div>
  """
end

select = fn assigns ->
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :name, nil)
  assigns = Map.put_new(assigns, :size, nil)
  assigns = Map.put_new(assigns, :value, nil)
  assigns = Map.put_new(assigns, :values, [])
  assigns = Map.put_new(assigns, :required, nil)

  ~H"""
  <select
  name={@name}
  size={@size}
  required={@required}
  class={[
    "p-2.5 rounded-lg border-0 ring-1 hover:ring-1",
    "bg-zinc-600 ring-zinc-600 text-neutral-400 focus:ring-lime-500",
    @class
  ]}>
  <option :for={value <- @values} value={value}
    selected={value==@value} title={value}
    class="p-2 checked:bg-lime-500 checked:text-white">
    {value}
  </option>
  </select>
  """
end

input = fn assigns ->
  # wont honor focus ring color if type nil
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :type, "text")
  assigns = Map.put_new(assigns, :name, nil)
  assigns = Map.put_new(assigns, :value, nil)
  assigns = Map.put_new(assigns, :disabled, nil)
  # number type
  assigns = Map.put_new(assigns, :step, nil)
  assigns = Map.put_new(assigns, :min, nil)
  assigns = Map.put_new(assigns, :max, nil)

  ~H"""
  <input
  type={@type}
  name={@name}
  value={@value}
  disabled={@disabled}
  step={@step}
  min={@min}
  max={@max}
  class={[
    "p-2.5 border-0 rounded-lg",
    "bg-zinc-600 ring-zinc-600 text-neutral-400 focus:ring-lime-500",
    @class
  ]}/>
  """
end

button = fn assigns ->
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :type, nil)
  assigns = Map.put_new(assigns, :event, nil)
  assigns = Map.put_new(assigns, :disabled, nil)

  ~H"""
  <button
  id={@id}
  type={@type}
  phx-click={@event}
  class={[
    "px-5 py-2.5 rounded-lg border-0 ring-1 hover:ring-1",
    @disabled || "bg-zinc-700 text-neutral-400 ring-neutral-600 hover:bg-lime-500 hover:text-white hover:ring-white hover:cursor-pointer",
    @disabled && "cursor-default pointer-events-none bg-neutral-800 text-neutral-600 ring-neutral-600",
    @class
  ]}>{render_slot(@inner_block)}</button>
  """
end

link = fn assigns ->
  assigns = phx_attribs.(assigns)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :disabled, nil)
  assigns = Map.put_new(assigns, :type, "normal")

  hover =
    case assigns.type do
      "danger" -> "hover:text-orange-500"
      _ -> "hover:text-lime-500"
    end

  assigns = Map.put_new(assigns, :hover, hover)

  ~H"""
  <div
  {@phx_attribs}
  class={[
    @disabled || "hover:cursor-pointer #{@hover}",
    @disabled && "cursor-default pointer-events-none",
    @class
  ]}>{render_slot(@inner_block)}</div>
  """
end

%{
  frame: frame,
  modal: modal,
  select: select,
  input: input,
  button: button,
  link: link
}
