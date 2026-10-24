use Terminal.Live

view = fn assigns ->
  ~H"""
  <div data-theme={@theme} class="flex flex-col items-center justify-center h-screen gap-4">
    <image src="/images/logo.svg" class="w-[8em]"/>
    <div class="text-3xl">{@hostname}</div>
    <form id="setup_form" class="grid grid-cols-[120px_1fr] gap-2 items-center" phx-hook="Form" phx-submit="form:submit">
      <div>Device Name</div>
      <input id="name" phx-hook="Focus" name="name" type="text" autocomplete="off"
        class="grow daisy-input daisy-input-bordered"
        value={@name}/>
      <div>Owner Email</div>
      <input name="owner" type="email" autocomplete="off"
        class="grow daisy-input daisy-input-bordered"
        value={@owner}/>
      <div/>
      <button type="submit"
        class="grow daisy-btn daisy-btn-outline"
        >Save</button>
    </form>
  </div>
  """
end

handler = fn
  {:mount, socket = %{assigns: assigns}, state} ->
    socket = assign(socket, applet_css: props[:applet_css] || "/applets/setup.css")
    socket = assign(socket, applet_js: props[:applet_js] || "/applets/setup.js")
    socket = assign(socket, page_title: "Setup")
    state = Map.put(state, :theme, props[:theme])
    state = Map.put(state, :hostname, assigns.hostname)
    state = Map.put(state, :name, Terminal.rconfig("name"))
    state = Map.put(state, :owner, Terminal.rconfig("owner"))
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:params, socket, state, params, uri} ->
    Log.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:event, socket, state, event = "form:submit", params = %{"name" => name, "owner" => owner}} ->
    Log.trace(view: path, event: event, params: params)
    state = Map.put(state, :name, name)
    state = Map.put(state, :owner, owner)

    spawn(fn ->
      Terminal.uconfig!("owner", owner)
      Terminal.uconfig!("name", name)
    end)

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

Terminal.view(path, handler)
