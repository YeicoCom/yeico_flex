defmodule Flex.Index do
  use Flex.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={@ui.frame} title="Home">
      <div class="flex flex-col gap-4 justify-center items-center overflow-y-auto h-full text-3xl">
        <.fui :for={{id, item} <- @items} fun={@ui.href} href={"/flex/user-screens/view?id=#{id}"}>{item.name}</.fui>
      </div>
    </.fui>
    """
  end

  defp filter_enabled(items) do
    Enum.filter(items, fn {_, v} -> v.status == :enabled end)
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    ui = Keyword.fetch!(opts, :ui)

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Home")
        items = Api.subget!("flex:user-screens:items") || []
        state = Map.put(state, :items, filter_enabled(items))
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

      {:info, socket, state, event = {"flex:user-screens:items", _, items}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :items, filter_enabled(items))
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
