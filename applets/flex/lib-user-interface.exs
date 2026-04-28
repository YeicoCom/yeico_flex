use Terminal.Live

# data-KEY for hooks
# phx-value-KEY for events
phxattr = fn assigns ->
  Map.put_new(
    assigns,
    :phxattr,
    for {k, v} <- assigns, reduce: %{} do
      acc ->
        case List.first(String.split("#{k}", "-")) in ["phx", "data"] do
          true -> Map.put(acc, k, v)
          _ -> acc
        end
    end
  )
end

frame = fn assigns ->
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :label, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :reverse, nil)
  assigns = Map.put_new(assigns, :title, "Flex")

  ~H"""
  <div id="main_frame" phx-window-keydown="modal:close" phx-key="Escape"
    class="flex flex-col gap-4 p-4 h-screen select-none text-base [&_*]:cursor-default">
    <div class={[@reverse && "z-20", "flex gap-4 p-4 items-center bg-zinc-800 rounded"]}>
      <div class="relative group text-white content-center">
        <button class="px-4 py-2 bg-zinc-500 rounded hover:bg-lime-500 hero-bars-3 size-10"></button>
        <div class="absolute top-3/4 hidden z-9998 group-hover:block w-48 bg-zinc-700 rounded shadow-xl mt-1">
          <a href="/flex" class="block px-4 py-2 hover:bg-lime-500">Flex Home</a>
          <a href="/flex/user-screens" class="block px-4 py-2 hover:bg-lime-500">User Screens</a>
          <a href="/flex/modbus-devices" class="block px-4 py-2 hover:bg-lime-500">Modbus Devices</a>
          <a href="/flex/modbus-terminal" class="block px-4 py-2 hover:bg-lime-500">Modbus Terminal</a>
          <a href="/flex/socket-terminal" class="block px-4 py-2 hover:bg-lime-500">Socket Terminal</a>
          <a href="/flex/serial-exports" class="block px-4 py-2 hover:bg-lime-500">Serial Exports</a>
          <a :if={Terminal.dev?()} href="/flex/dev-generic-items" class="block px-4 py-2 hover:bg-lime-500">Dev Generic Items</a>
          <a :if={Terminal.dev?()} href="/flex/dev-ui-tester" class="block px-4 py-2 hover:bg-lime-500">Dev UI Tester</a>
        </div>
      </div>
      <div class="text-[2em] text-white">{@title}</div>
      <div class="grow"></div>
      <div :if={@label} class="text-[1.5em] text-white">{@label}</div>
      <image src="/applets/logo.svg" class="h-10"/>
    </div>
    <div class={[@reverse && "z-10", "grow text-neutral-300 overflow-hidden", @class]}>
      {render_slot(@inner_block)}
    </div>
  </div>
  """
end

# modal assumed to be layed outside frame
modal = fn assigns ->
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :title, nil)
  assigns = Map.put_new(assigns, :close, "modal:close")
  assigns = Map.put_new(assigns, :away, "modal:away")

  ~H"""
  <div class="fixed top-0 left-0 z-9999 w-screen h-screen bg-neutral-200/50">
    <div class="flex justify-center items-center h-screen">
      <div class={["p-8 rounded-md bg-neutral-800", @class]} phx-click-away={@away}>
        <div class="pb-2 gap-20 flex justify-between items-center text-gray-400">
          <div class="text-white text-lg font-semibold">{@title}</div>
          <button type="button" title="Close" phx-click={@close}
            class="hover:bg-gray-600 hover:text-white rounded-lg w-8 h-8 inline-flex justify-center items-center">
            <span class="hero-x-mark-solid z-0" />
          </button>
        </div>
        {render_slot(@inner_block)}
      </div>
    </div>
  </div>
  """
end

select = fn assigns ->
  assigns = phxattr.(assigns)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :name, nil)
  assigns = Map.put_new(assigns, :size, nil)
  assigns = Map.put_new(assigns, :value, nil)
  assigns = Map.put_new(assigns, :values, [])
  assigns = Map.put_new(assigns, :required, nil)
  assigns = Map.put_new(assigns, :disabled, nil)

  ~H"""
  <select
  id={@id}
  name={@name}
  size={@size}
  required={@required}
  disabled={@disabled}
  {@phxattr}
  class={[
    "px-2 py-1 border-0 rounded-lg ring-1 outline-none",
    "bg-zinc-600 text-neutral-200 ring-zinc-600",
    "disabled:pointer-events-none disabled:ring-zinc-500",
    "disabled:bg-zinc-700 disabled:text-neutral-500",
    "focus:ring-lime-500",
    "hover:ring-lime-500",
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
  assigns = phxattr.(assigns)
  # wont honor focus ring color if type nil
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :type, "text")
  assigns = Map.put_new(assigns, :name, nil)
  assigns = Map.put_new(assigns, :value, nil)
  assigns = Map.put_new(assigns, :disabled, nil)
  assigns = Map.put_new(assigns, :title, nil)
  assigns = Map.put_new(assigns, :required, nil)
  assigns = Map.put_new(assigns, :size, nil)
  # number type
  assigns = Map.put_new(assigns, :step, nil)
  assigns = Map.put_new(assigns, :min, nil)
  assigns = Map.put_new(assigns, :max, nil)
  # text type
  assigns = Map.put_new(assigns, :pattern, nil)
  # validation
  assigns = Map.put_new(assigns, :error, nil)
  assigns = Map.put_new(assigns, :error?, !!assigns.error)

  ~H"""
  <input
  id={@id}
  type={@type}
  name={@name}
  value={@value}
  disabled={@disabled}
  required={@required}
  pattern={@pattern}
  title={@error || @title}
  size={@size}
  step={@step}
  min={@min}
  max={@max}
  {@phxattr}
  class={[
    "px-2 py-1 border-0 rounded-lg ring-1",
    "ring-zinc-600 outline-none",
    !@error? && "bg-zinc-600 text-neutral-200",
    @error? && "bg-red-800 text-neutral-200",
    "disabled:pointer-events-none disabled:ring-zinc-500",
    "disabled:bg-zinc-700 disabled:text-neutral-500",
    "focus:ring-lime-500",
    "hover:ring-lime-500",
    @class
  ]}/>
  """
end

button = fn assigns ->
  assigns = phxattr.(assigns)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :type, nil)
  assigns = Map.put_new(assigns, :disabled, nil)

  ~H"""
  <button
  id={@id}
  type={@type}
  disabled={@disabled}
  {@phxattr}
  class={[
    "px-2 py-1 border-0 rounded-lg ring-1 outline-none",
    "bg-zinc-600 text-neutral-200 ring-zinc-600",
    "disabled:pointer-events-none disabled:ring-zinc-500",
    "disabled:bg-zinc-700 disabled:text-neutral-500",
    "focus:ring-lime-500 focus:text-white focus:bg-lime-500",
    "hover:ring-lime-500 hover:text-white hover:bg-lime-500",
    @class
  ]}>{render_slot(@inner_block)}</button>
  """
end

link = fn assigns ->
  assigns = phxattr.(assigns)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :title, nil)
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
  id={@id}
  title={@title}
  disabled={@disabled}
  {@phxattr}
  class={[
    "flex items-center gap-1",
    !@disabled && "text-neutral-200 #{@hover}",
    @disabled && "text-neutral-500 pointer-events-none",
    @class
  ]}>{render_slot(@inner_block)}</div>
  """
end

href = fn assigns ->
  assigns = phxattr.(assigns)
  assigns = Map.put_new(assigns, :id, nil)
  assigns = Map.put_new(assigns, :class, nil)
  assigns = Map.put_new(assigns, :title, nil)
  assigns = Map.put_new(assigns, :disabled, nil)
  assigns = Map.put_new(assigns, :href, nil)

  ~H"""
  <a
  id={@id}
  href={@href}
  title={@title}
  disabled={@disabled}
  {@phxattr}
  class={[
    "flex items-center gap-1",
    !@disabled && "text-neutral-200 hover:text-lime-500",
    @disabled && "text-neutral-500 pointer-events-none",
    @class
  ]}>{render_slot(@inner_block)}</a>
  """
end

%{
  phxattr: phxattr,
  frame: frame,
  modal: modal,
  select: select,
  button: button,
  input: input,
  link: link,
  href: href
}
