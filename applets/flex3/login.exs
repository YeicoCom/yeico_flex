use Terminal.Live

# both nowraps came from absolute position approach and left to reflect intent but not needed under grid layout
# google button layout problems become evident when running on flex.yeico.com as opposed to localhost:4080
# grid layout with both divs in same cell fixes the absolute positioning failing to calculate parent height
# working with opacity instead of hidded minimizes relayout flickers
# make the overlapping button large enough to minimize relayout flickers
# see notices in gauth.js
view = fn assigns ->
  ~H"""
  <div id="gauth_main" phx-hook="Gauth" class="flex flex-col items-center justify-center h-screen gap-2 bg-base-300">
    <div id="gauth_panel" class="flex flex-col items-center justify-center px-24 py-8 rounded bg-base-100 text-base-content">
      <image :if={@logo} src={@logo} class="w-[4em] grayscale"/>
      <div :if={@label} class="text-3xl">{@label}</div>
      <div id="gauth_button_panel" phx-update="ignore" class="flex flex-col items-center justify-center pt-2">
        <div id="g_id_onload" data-auto_prompt="false" data-callback="gauthHandleResponse" data-client_id={@client_id}/>
        <div id="gauth_button_layers" class="opacity-0 grid grid-cols-1 place-items-center">
          <div id="gauth_button_original" class="g_id_signin opacity-0 col-start-1 row-start-1"/>
          <div id="gauth_button_custom"
            class="opacity-0 w-full h-full col-start-1 row-start-1 pointer-events-none daisy-btn daisy-btn-neutral daisy-btn-sm flex flex-nowrap items-center gap-1">
            <image :if={@glogo} src={@glogo} class="w-[1.5em] grayscale"/>
            <div class="text-nowrap text-sm">Sign in with Google</div>
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
