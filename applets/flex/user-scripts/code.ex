defmodule Flex.UserScripts.Code do
  alias Flex.UserScripts.IUtils
  use Flex.Use.Live

  defp view(assigns) do
    ~H"""
    <.fui fun={&UI.frame/1} title="Script Editor" label={@name} badge={@users} class="grid grid-cols-2">
      <div id="script_editor" class="overflow-y-scroll bg-[#282c34]" phx-hook="CodeEditor" phx-update="ignore"/>
      <div phx-update="stream" id="logs" class="flex flex-col overflow-y-scroll text-xs select-text font-mono" phx-hook="AutoScroll">
        <div :for={{id, %{stamp: stamp, level: level, style: style, line: line}} <- @streams.logs}
          id={id} class={style}>{stamp} {level} {line}</div>
      </div>
    </.fui>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    cdb = Keyword.fetch!(opts, :cdb)

    fn
      {:mount, socket, state} ->
        tzoffset = socket.assigns.tzoffset || 0
        socket = assign(socket, applet_css: "/applets/flex.css")
        socket = assign(socket, applet_js: "/applets/flex.js")
        socket = assign(socket, page_title: "Script Editor")
        socket = assign(socket, page_suffix: " · Flex")
        socket = stream(socket, :logs, [])
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :users, nil)
        state = Map.put(state, :name, nil)
        state = Map.put(state, :logid, 0)
        state = Map.put(state, :id, nil)
        {socket, state}

      {:params, socket = %{assigns: %{connected?: connected?}}, state, params = %{"id" => id},
       uri} ->
        Log.trace(view: path, params: params, uri: uri)
        Bus.subscribe!("flex:user-scripts:change:#{id}")
        Applet.subscribe!(:trace, id, nil)
        if connected?, do: Api.defer(fn -> Bus.broadcast!("flex:user-scripts:users", nil) end)
        if connected?, do: Bus.subscribe!("flex:user-scripts:users")
        if connected?, do: Mdb.register!({:script, id}, nil)
        Bus.broadcast!("flex:user-scripts:users", nil)
        # it may not exist: use script[:name] assessor
        script = Api.subget!("flex:user-scripts:item:#{id}")
        state = Map.put(state, :name, script[:name])
        state = Map.put(state, :id, id)
        socket = push_event(socket, "hook:init", %{code: IUtils.load(cdb, id)})
        {socket, state}

      {:render, assigns, state} ->
        state = Map.put(state, :streams, assigns.streams)
        view(state)

      {:event, socket, state = %{id: id, name: name}, event = "hook:save",
       params = %{"code" => code}} ->
        Log.trace(view: path, event: event, params: params)
        # prevent loop crash while attemping to reload runner
        if name, do: IUtils.save(cdb, id, code, false)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{id: id, logid: logid}, event = {{:logger, id, level}, _, line}} ->
        Log.trace(view: path, info: event)
        line = line |> String.replace_prefix("script ", "")
        stamp = NaiveDateTime.utc_now() |> NaiveDateTime.shift(hour: state.tzoffset)
        log = %{id: logid, stamp: stamp, level: level, style: IUtils.style(level), line: line}
        socket = stream(socket, :logs, [log])
        state = Map.update!(state, :logid, &(&1 + 1))
        {socket, state}

      # reload only on delete to catch reenable logs
      {:info, socket, state = %{id: id}, event = {"flex:user-scripts:item:" <> id, _, nil}} ->
        Log.trace(view: path, info: event)
        socket = push_event(socket, "hook:reload", %{})
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-scripts:item:" <> id, _, script}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :name, script[:name])
        # below line only required if copy/paste is implemented
        # but pasting can be directly performed on code mirror editor
        # socket = push_event(socket, "hook:init", %{code: IUtils.load.(id)})
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-scripts:change:" <> id, _, pid}} ->
        Log.trace(view: path, info: event)
        socket = if(self() != pid, do: push_event(socket, "hook:reload", %{}), else: socket)
        {socket, state}

      {:info, socket, state = %{id: id}, event = {"flex:user-scripts:users", _, _}} ->
        Log.trace(view: path, info: event)
        state = Map.put(state, :users, Mdb.lookup({:script, id}) |> Enum.count())
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
