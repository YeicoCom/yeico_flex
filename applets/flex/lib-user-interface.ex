defmodule Flex.UI do
  use Flex.Live

  # data-KEY for hooks
  # phx-value-KEY for events
  def phxattr(assigns) do
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

  def frame(assigns) do
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :label, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :title, "Flex")
    assigns = Map.put_new(assigns, :dev?, Terminal.dev?())
    assigns = Map.put_new(assigns, :device?, Terminal.device?())

    ~H"""
    <div id="main_frame" phx-window-keydown="modal:close" phx-key="Escape" phx-hook="AllPages"
      class="flex flex-col h-screen select-none text-base [&_*]:cursor-default">
      <div class="flex gap-2 p-2 items-center bg-zinc-800 text-white">
        <div class="text-lg font-bold">{@title}</div>
        <div class="grow"/>
        <div :if={@label}>{@label}</div>
        <image src="/applets/logo.svg" class="h-6"/>
      </div>
      <div class="grow flex overflow-hidden">
        <div class="group flex">
          <div class="w-1 group-hover:hidden"/>
          <div class="hidden group-hover:block h-full w-max bg-zinc-800 text-white">
            <a href="/flex" class="block px-4 py-2 hover:bg-lime-500">Flex Home</a>
            <a href="/flex/user-files" class="block px-4 py-2 hover:bg-lime-500">User Files</a>
            <a href="/flex/user-scripts" class="block px-4 py-2 hover:bg-lime-500">User Scripts</a>
            <a href="/flex/user-screens" class="block px-4 py-2 hover:bg-lime-500">User Screens</a>
            <a href="/flex/user-backends" class="block px-4 py-2 hover:bg-lime-500">User Backends</a>
            <a href="/flex/modbus-devices" class="block px-4 py-2 hover:bg-lime-500">Modbus Devices</a>
            <a href="/flex/modbus-terminal" class="block px-4 py-2 hover:bg-lime-500">Modbus Terminal</a>
            <a href="/flex/socket-terminal" class="block px-4 py-2 hover:bg-lime-500">Socket Terminal</a>
            <a href="/flex/serial-exports" class="block px-4 py-2 hover:bg-lime-500">Serial Exports</a>
            <a :if={@dev?} href="/flex/ui-tester" class="block px-4 py-2 hover:bg-lime-500">UI Tester</a>
            <a :if={@device?} href="/flex/config" class="block px-4 py-2 hover:bg-lime-500">Config</a>
            <a href="/flex/logout" class="block px-4 py-2 hover:bg-lime-500">Logout</a>
          </div>
        </div>
        <div class={["grow text-neutral-300", @class]}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  # modal assumed to be laid outside frame
  def modal(assigns) do
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :close, "modal:close")
    assigns = Map.put_new(assigns, :away, "modal:away")

    ~H"""
    <div class="fixed top-0 left-0 z-9999 w-screen h-screen bg-neutral-200/50">
      <div class="flex justify-center items-center h-screen select-none text-base [&_*]:cursor-default">
        <div class={["p-8 rounded-md bg-neutral-800", @class]} phx-click-away={@away}>
          <div class="pb-2 gap-20 flex justify-between items-center">
            <div class="text-white text-lg font-semibold">{@title}</div>
            <button type="button" title="Close" phx-click={@close}
              class="hover:bg-gray-600 hover:text-white rounded-lg w-8 h-8 inline-flex justify-center items-center">
              <span class="hero-x-mark-solid" />
            </button>
          </div>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  def select(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :name, nil)
    assigns = Map.put_new(assigns, :size, nil)
    assigns = Map.put_new(assigns, :value, nil)
    assigns = Map.put_new(assigns, :values, [])
    assigns = Map.put_new(assigns, :values2, [])
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
      class="p-2 checked:bg-lime-500 checked:text-white">{value}</option>
    <option :for={{value, label} <- @values2} value={value}
      selected={value==@value} title={label}
      class="p-2 checked:bg-lime-500 checked:text-white">{label}</option>
    </select>
    """
  end

  def input(assigns) do
    assigns = phxattr(assigns)
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
      !@error && "bg-zinc-600 text-neutral-200",
      @error && "bg-red-800 text-neutral-200",
      "disabled:pointer-events-none disabled:ring-zinc-500",
      "disabled:bg-zinc-700 disabled:text-neutral-500",
      "focus:ring-lime-500",
      "hover:ring-lime-500",
      @class
    ]}/>
    """
  end

  def area(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :name, nil)
    assigns = Map.put_new(assigns, :value, nil)
    assigns = Map.put_new(assigns, :disabled, nil)
    assigns = Map.put_new(assigns, :readonly, nil)
    assigns = Map.put_new(assigns, :title, nil)
    assigns = Map.put_new(assigns, :required, nil)
    assigns = Map.put_new(assigns, :rows, nil)
    # validation
    assigns = Map.put_new(assigns, :error, nil)

    ~H"""
    <textarea
    id={@id}
    name={@name}
    disabled={@disabled}
    readonly={@readonly}
    required={@required}
    title={@error || @title}
    rows={@rows}
    {@phxattr}
    class={[
      "px-2 py-1 border-0 rounded-lg ring-1",
      "ring-zinc-600 outline-none",
      !@error && "bg-zinc-600 text-neutral-200",
      @error && "bg-red-800 text-neutral-200",
      "disabled:pointer-events-none disabled:ring-zinc-500",
      "disabled:bg-zinc-700 disabled:text-neutral-500",
      "focus:ring-lime-500",
      "hover:ring-lime-500",
      @class
    ]}>{@value}</textarea>
    """
  end

  def button(assigns) do
    assigns = phxattr(assigns)
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

  def link(assigns) do
    assigns = phxattr(assigns)
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

  def href(assigns) do
    assigns = phxattr(assigns)
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

  def code(assigns) do
    assigns = phxattr(assigns)
    assigns = Map.put_new(assigns, :id, nil)
    assigns = Map.put_new(assigns, :class, nil)
    assigns = Map.put_new(assigns, :name, nil)
    assigns = Map.put_new(assigns, :value, nil)
    # validation
    assigns = Map.put_new(assigns, :error, nil)
    # lang selection
    assigns = Map.put_new(assigns, :lang, nil)

    ~H"""
    <div title={@error}>
      <div
      id={@id}
      {@phxattr}
      phx-update="ignore"
      phx-hook="CodeArea"
      data-lang={@lang}
      class={[
        "px-2 py-1 border-0 rounded-lg ring-1",
        "ring-zinc-600 outline-none",
        "bg-zinc-600 text-neutral-200",
        "focus:ring-lime-500",
        "hover:ring-lime-500",
        @class
      ]}/>
      <textarea name={@name} class="hidden">{@value}</textarea>
    </div>
    """
  end
end
