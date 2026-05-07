defmodule Flex.UITester do
  use Flex.Live

  @select ["Item 1", "Item 2"]
  @options %{select: @select}

  defp view(assigns) do
    ~H"""
    <.fui fun={@ui.frame} title="UI Tester">
      <.fui fun={@ui.link} phx-click="click:link1">
        <div class="hero-plus"/>Link1
      </.fui>
      <.fui fun={@ui.link} phx-click="click:link2" type="danger">
        <div class="hero-plus"/>Link2
      </.fui>
      <.fui fun={@ui.link} phx-click="click:link3" disabled>
        <div class="hero-plus"/>Link3
      </.fui>
      <form id="form1" phx-submit="form:submit" phx-change="form:change"
        class="flex px-1 py-2 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.select} name="select1" value={@input[:select1]} values={@options.select} required/>
        <.fui fun={@ui.select} name="select2" value={@input[:select2]} values={@options.select} required disabled/>
        <.fui fun={@ui.input} name="text1" value={@input[:text1]} type="text" class="grow" id="autofocus1" phx-hook="AutoFocus"/>
        <.fui fun={@ui.input} name="text2" value={@input[:text2]} type="text" class="grow" disabled/>
        <.fui fun={@ui.select} name="select3" value={@input[:select3]} values={@options.select} required disabled/>
        <.fui fun={@ui.button} type="submit" disabled>Send1</.fui>
      </form>
      <form id="form2" phx-submit="form:submit" phx-change="form:change"
        class="flex px-1 py-2 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.select} name="select1" value={@input[:select1]} values={@options.select} required/>
        <.fui fun={@ui.select} name="select2" value={@input[:select2]} values={@options.select} required disabled/>
        <.fui fun={@ui.input} name="text1" value={@input[:text1]} type="text" class="grow"/>
        <.fui fun={@ui.input} name="text2" value={@input[:text2]} type="text" class="grow" disabled/>
        <.fui fun={@ui.button} type="submit" disabled>Send1</.fui>
        <.fui fun={@ui.button} type="submit">Send2</.fui>
      </form>
      <form id="form3" phx-submit="form:submit" phx-change="form:change"
        class="flex flex-col px-1 py-2 gap-2" phx-hook="EnterNavigation" autocomplete="off">
        <.fui fun={@ui.area} name="text1" value={@input[:text1]} class="grow" disabled/>
        <.fui fun={@ui.area} name="text2" value={@input[:text2]} class="grow" readonly/>
        <.fui fun={@ui.area} name="text3" value={@input[:text3]} class="grow"/>
        <.fui fun={@ui.button} type="submit">Send</.fui>
      </form>
    </.fui>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    ui = Keyword.fetch!(opts, :ui)

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "UI Tester")
        socket = assign(socket, page_suffix: " · Flex")
        state = Map.put(state, :input, %{text1: "Text", text2: "Text"})
        state = Map.put(state, :options, @options)
        state = Map.put(state, :ui, ui)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, reason} ->
        Log.trace(view: path, close: reason)
        :ok
    end
  end
end

:ok
