use Terminal.Live

view = fn assigns ->
  ~H"""
  <div id="gauth_main" phx-hook="Gauth" class="flex flex-col items-center justify-center h-screen gap-2 bg-base-300">
    <div id="gauth_panel" class="flex flex-col items-center justify-center px-24 py-8 rounded bg-base-100 text-base-content">
      <image :if={@logo} src={@logo} class="w-[4em] grayscale"/>
      <div :if={@label} class="text-3xl">{@label}</div>
      <div id="gauth_button_panel" class="flex flex-col items-center justify-center pt-2">
        <div id="g_id_onload" data-auto_prompt="false" data-callback="gauthHandleResponse" data-client_id={@client_id}/>
        <div id="gauth_button_layers" class="relative hidden">
          <div id="gauth_button_container" phx-update="ignore" class="g_id_signin opacity-0"/>
          <div id="gauth_button_rendered" phx-update="ignore" style="left:0px;top:0px;"
            class="pointer-events-none absolute daisy-btn daisy-btn-bordered w-fit h-fit daisy-btn-neutral p-2 flex flex-nowrap items-center gap-1">
            <image :if={@glogo} src={@glogo} class="w-[2em] grayscale"/>
            <div class="text-nowrap">Sign in with Google</div>
          </div>
        </div>
      </div>
    </div>
  </div>
  """
end

handler = fn
  {:mount, socket = %{assigns: %{params: params}}, state} ->
    applet = props[:applet_name] || "flex3"
    referer = Base.decode16!(params["to"] || "2F")
    socket = assign(socket, applet_css: props[:applet_css] || "/applets/#{applet}.css")
    socket = assign(socket, applet_js: props[:applet_js] || "/applets/#{applet}.js")
    socket = assign(socket, page_suffix: props[:page_suffix] || " · Flex")
    socket = assign(socket, page_title: props[:page_title] || "Login")
    socket = assign(socket, applet_args: props[:applet_args])
    state = Map.put(state, :glogo, props[:glogo] || "/applets/#{applet}/gauth.svg")
    state = Map.put(state, :logo, props[:logo] || "/applets/logo.svg")
    state = Map.put(state, :label, props[:label] || "Flex")
    state = Map.put(state, :client_id, Flex.Gauth.client_id())
    state = Map.put(state, :referer, referer)
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    view.(state)

  {:event, socket, state = %{referer: referer, client_id: client_id}, "gauth:auth", params} ->
    socket = Flex.Gauth.push_login(socket, referer, client_id, params)
    {socket, state}

  {:event, socket, state, _event, _params} ->
    {socket, state}

  {:info, socket, state, _event} ->
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view(path, handler)
