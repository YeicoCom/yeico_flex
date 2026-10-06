defmodule Flex.View do
  use Terminal.Live
  alias Flex.Repo
  alias Flex.Buffer

  # update ignore or blank screen on reconnected
  defp view(assigns) do
    ~H"""
    <div id="app" class="dockview-theme-abyss coder-invisible" phx-hook="Coder" phx-update="ignore"/>
    <div id="rename" class="modal">
      <div class="modal-overlay" tabindex="-1" data-micromodal-close>
        <div id="rename-content"/>
      </div>
    </div>
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
        socket = assign(socket, page_suffix: " · Flex")
        socket = assign(socket, page_title: "Home")
        state = Map.put(state, :connected?, connected?)
        state = Map.put(state, :tzoffset, tzoffset)
        {socket, state}

      {:params, socket, state = %{tzoffset: tzoffset, connected?: true}, _params, _uri} ->
        Bus.subscribe!(:buffer)

        logs =
          for {path, list} <- Buffer.register("buffer"), reduce: %{} do
            logs ->
              list =
                for log = %{stamp: stamp} <- list, reduce: [] do
                  list ->
                    log = %{log | stamp: Flex.Log.stamp(tzoffset, stamp)}
                    [log | list]
                end

              Map.put(logs, path, list)
          end

        {_pid, _root, files} = Repo.register("repo")
        files = for {p, {e, d}} <- files, do: %{path: p, data: d, enabled: e}
        socket = push_event(socket, "hook:init", %{files: files, logs: logs})
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state} ->
        view(state)

      {:event, socket, state, "hook:add", %{"type" => type}} ->
        {p, {e, d}} = Repo.fs(:add, repo, type)
        socket = push_event(socket, "hook:add", %{path: p, data: d, enabled: e})
        {socket, state}

      {:event, socket, state, "hook:del", %{"path" => path}} ->
        Repo.fs(:rm, repo, path)
        {socket, state}

      {:event, socket, state, "hook:start", %{"path" => path}} ->
        Repo.fs(:enable, repo, path)
        {socket, state}

      {:event, socket, state, "hook:stop", %{"path" => path}} ->
        Repo.fs(:disable, repo, path)
        {socket, state}

      {:event, socket, state, "hook:rename", %{"path" => path, "new" => new}} ->
        {p, {e, d}} = Repo.fs(:rename, repo, path, new)
        data = %{path: p, data: d, enabled: e}
        socket = if(p, do: push_event(socket, "hook:add", data), else: socket)
        {socket, state}

      {:event, socket, state, "hook:save", %{"path" => path, "data" => data}} ->
        Repo.fs(:save, repo, path, data)
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{tzoffset: tzoffset}, {:buffer, _, {id, stamp, path, level, msg}}} ->
        stamp = Flex.Log.stamp(tzoffset, stamp)
        log = %{id: id, stamp: stamp, path: path, level: level, msg: msg}
        socket = push_event(socket, "hook:log", log)
        {socket, state}

      {:info, socket, state, {Repo, path, {enabled, data}}} ->
        socket = push_event(socket, "hook:updated", %{path: path, data: data, enabled: enabled})
        {socket, state}

      {:info, socket, state, {Repo, path, nil}} ->
        socket = push_event(socket, "hook:deleted", %{path: path})
        {socket, state}

      # monitoring repo and buffer
      {:info, socket, state, {:DOWN, _ref, :process, _pid, _reason}} ->
        exit(:kill)
        {socket, state}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end
end
