use Terminal.Live

view = fn assigns ->
  ~H"""
  <div class="flex flex-col items-center justify-center h-screen gap-4">
    <image src="/images/logo.svg" class="w-[8em]"/>
    <div class="text-3xl text-gray">{@hostname}</div>
    <form class="grid grid-cols-[120px_1fr] gap-2 items-center text-xs text-gray-200" phx-change="input:change" phx-submit="input:save">
      <div>Device Name</div>
      <input id="name" phx-hook="AutoFocus" name="name" type="text" autocomplete="off" title="Press Enter to Save"
        class={[
          "grow text-base p-1.5 rounded-lg bg-zinc-600 text-neutral-400",
          "focus:border-2 focus:outline-none focus:ring-0 focus:border-lime-500",
        ]} value={@input[:name]}
      />
      <div>Owner Email</div>
      <input name="owner" type="email" autocomplete="off" title="Press Enter to Save"
        class={[
          "grow text-base p-1.5 rounded-lg bg-zinc-600 text-neutral-400",
          "focus:border-2 focus:outline-none focus:ring-0 focus:border-lime-500",
        ]} value={@input[:owner]}
      />
      <button type="submit" class={[
        "col-span-2 py-4",
        "p-1.5 rounded-lg bg-zinc-700 text-neutral-400",
        "hover:bg-lime-500 hover:text-white hover:cursor-pointer",
        ]}>Save</button>
    </form>
    <style>body {background-image: url("/images/waves.jpg"); background-position: center; background-size: cover;}</style>
  </div>
  """
end

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/setup.css")
    socket = assign(socket, applet_js: "/applets/setup.js")
    socket = assign(socket, page_title: "Setup")
    state = Map.put(state, :hostname, socket.assigns.hostname)

    state =
      Map.put(state, :input, %{
        name: Terminal.rconfig("name"),
        owner: Terminal.rconfig("owner")
      })

    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:params, socket, state, params, uri} ->
    Log.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:event, socket, state, event = "input:change", params = %{"_target" => [target]}} ->
    Log.trace(view: path, event: event, params: params)
    state = put_in(state, [:input, String.to_atom(target)], params[target])
    {socket, state}

  {:event, socket, state, event = "input:save", params = %{"name" => name, "owner" => owner}} ->
    Log.trace(view: path, event: event, params: params)

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
