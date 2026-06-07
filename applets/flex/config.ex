defmodule Flex.ConfigView do
  use Flex.Use.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Config" class="flex flex-col justify-center items-center h-full">
      <form id="monitor_view" phx-submit="submit:apply" class="flex flex-col gap-2" autocomplete="off">
        <div class="text-3xl">Monitor Resolution</div>
        <div :for={{name, modes} <- @cards} class="grid grid-cols-2 gap-2 items-center">
          <div>{name}</div>
          <.fui fun={&UI.select/1} name={name} values={modes} required/>
        </div>
        <.fui fun={&UI.button/1} type="submit" class="col-span-2">Apply</.fui>
        <.fui fun={&UI.button/1} type="button" class="col-span-2" phx-click="submit:reset">Reset</.fui>
      </form>
    </.fui>
    """
  end

  defp modes(name) do
    case File.read("/sys/class/drm/#{name}/modes") do
      {:ok, data} -> String.split(data, "\n", trim: true)
      _ -> []
    end
    |> Enum.uniq()
  end

  defp init(false, state), do: Map.put(state, :cards, [])

  defp init(true, state) do
    cards =
      Path.wildcard("/sys/class/drm/card?-*-*/status")
      |> Enum.filter(&(File.read(&1) == {:ok, "connected\n"}))
      |> Enum.map(&Path.basename(Path.dirname(&1)))
      |> Enum.map(fn name -> {name, ["off" | modes(name)]} end)

    Map.put(state, :cards, cards)
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Config")
        state = init(Terminal.device?(), state)
        {socket, state}

      {:params, socket, state, params, uri} ->
        Log.trace(view: path, params: params, uri: uri)
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, event = "submit:apply", params} ->
        Log.trace(view: path, event: event, params: params)
        # DSI,HDMI,VGA,Virtual,LVDS
        # kingdel requires LVDS-1 off
        # cat "/data/terminal/config/weston"

        if Terminal.device?() do
          config =
            Enum.map(params, fn {name, mode} ->
              [_p0 | parts] = String.split(name, "-")
              "[output]\nname=#{Enum.join(parts, "-")}\nmode=#{mode}"
            end)
            |> Enum.join("\n")

          Terminal.wconfig!("weston", config)
          System.shell("killall cog")
        end

        {socket, state}

      {:event, socket, state, event = "submit:reset", params} ->
        Log.trace(view: path, event: event, params: params)

        if Terminal.device?() do
          Terminal.wconfig!("weston", "")
          System.shell("killall cog")
        end

        {socket, state}

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
