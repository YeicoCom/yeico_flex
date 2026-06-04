defmodule Flex2.View do
  use Terminal.Live
  alias Flex2.Repo
  alias Flex2.Buffer

  # update ignore or blank screen on reconnected
  defp view(assigns) do
    ~H"""
    <div id="app" class="dockview-theme-abyss coder-invisible" phx-hook="Coder" phx-update="ignore"/>
    """
  end

  def handler(opts) do
    path = Keyword.fetch!(opts, :path)
    repo = Keyword.fetch!(opts, :repo)

    fn
      {:mount, socket = %{assigns: assigns}, state} ->
        tzoffset = assigns.tzoffset || 0
        connected? = assigns.connected?
        socket = assign(socket, applet_css: "/applets/flex2.css")
        socket = assign(socket, applet_js: "/applets/flex2.js")
        socket = assign(socket, page_suffix: " · Flex2")
        socket = assign(socket, page_title: "Home")
        state = Map.put(state, :connected?, connected?)
        state = Map.put(state, :tzoffset, tzoffset)
        {socket, state}

      {:params, socket, state = %{tzoffset: tzoffset, connected?: true}, _params, _uri} ->
        Bus.subscribe!(:buffer)

        logs =
          for {path, list} <- Buffer.state(), reduce: %{} do
            logs ->
              list =
                for log = %{stamp: stamp} <- list, reduce: [] do
                  list ->
                    log = %{log | stamp: Flex2.Log.stamp(tzoffset, stamp)}
                    [log | list]
                end

              Map.put(logs, path, list)
          end

        {_root, files} = Repo.register()
        files = for {p, {e, d}} <- files, do: %{path: p, data: d, enabled: e}
        socket = push_event(socket, "hook:init", %{files: files, logs: logs})
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, "hook:add", %{"type" => type}} ->
        {p, {e, d}} = Repo.add(repo, type)
        socket = push_event(socket, "hook:add", %{path: p, data: d, enabled: e})
        {socket, state}

      {:event, socket, state, "hook:del", %{"path" => path}} ->
        Repo.del(repo, path)
        {socket, state}

      {:event, socket, state, "hook:start", %{"path" => path}} ->
        Repo.start(repo, path)
        {socket, state}

      {:event, socket, state, "hook:stop", %{"path" => path}} ->
        Repo.stop(repo, path)
        {socket, state}

      {:event, socket, state, "hook:save", %{"path" => path, "data" => data}} ->
        Repo.save(repo, path, data)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset}, {:buffer, _, {id, stamp, path, level, msg}}} ->
        stamp = Flex2.Log.stamp(tzoffset, stamp)
        log = %{id: id, stamp: stamp, path: path, level: level, msg: msg}
        socket = push_event(socket, "hook:log", log)
        {socket, state}

      {:info, socket, state, {Repo, path, {enabled, data}}} ->
        socket = push_event(socket, "hook:updated", %{path: path, data: data, enabled: enabled})
        {socket, state}

      {:info, socket, state, {Repo, path, nil}} ->
        socket = push_event(socket, "hook:deleted", %{path: path})
        {socket, state}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end
end
