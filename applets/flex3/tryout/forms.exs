use Terminal.Live

render = fn assigns ->
  ~H"""
  <form id="form_id" phx-submit="form:submit" class="p-4 flex gap-1" phx-hook="Form">
    <div class="w-1/2 flex flex-col gap-1">
      <button class="flex-button">Click me</button>
      <button class="flex-button" disabled>Click me</button>
      <input type="text" class="flex-input" value="Form Input">
      <input type="text" class="flex-input" value="Form Input" readonly>
      <input type="text" class="flex-input" value="Form Input" disabled>
      <input type="number" class="flex-input" value="1.23">
      <input type="number" class="flex-input" value="1.23" readonly>
      <input type="number" class="flex-input" value="1.23" disabled>
      <select class="flex-select">
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
      <select class="flex-select" disabled>
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-1">
          <input type="radio" name="r" id="r1" class="flex-radio">
          <label for="r1">Radio1</label>
        </div>
        <div class="flex items-center gap-1">
          <input type="radio" name="r" id="r2" class="flex-radio" checked>
          <label for="r2">Radio2</label>
        </div>
        <div class="flex items-center gap-1">
          <input type="radio" name="r" id="r3" class="flex-radio" disabled>
          <label for="r3">Radio3</label>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-1">
          <input type="checkbox" name="c1" id="c1" class="flex-checkbox">
          <label for="c1">Checkbox1</label>
        </div>
        <div class="flex items-center gap-1">
          <input type="checkbox" name="c2" id="c2" class="flex-checkbox" checked>
          <label for="c2">Checkbox2</label>
        </div>
        <div class="flex items-center gap-1">
          <input type="checkbox" name="rc" id="c3" class="flex-checkbox" disabled>
          <label for="c3">Checkbox3</label>
        </div>
      </div>
      <a class="flex-button"><span class="hero-check"/>Link A Button</a>
      <a class="flex-link"><span class="hero-check"/>Link A</a>
      <div class="flex-link"><span class="hero-check"/>Link Div</div>
    </div>
    <div class="w-1/2 flex flex-col gap-1">
      <select size="4" class="flex-select bg-none">
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
      <select size="4" class="flex-select bg-none" disabled>
        <option value="1">One</option>
        <option value="2">Two</option>
      </select>
      <textarea lines="3" class="flex-textarea">Hello&#10;World</textarea>
      <textarea lines="3" class="flex-textarea" readonly>Hello&#10;World</textarea>
      <textarea lines="3" class="flex-textarea" disabled>Hello&#10;World</textarea>
    </div>
  </form>
  """
end

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/form1")
|> Flex.LiveScreen.set(title: "Form1")
|> Flex.LiveScreen.set(width: 600)
|> Flex.LiveScreen.set(height: 800)
|> Flex.LiveScreen.add(
  {0, 0},
  Flex.ReactorWrapper,
  handler: fn
    assigns = %{event: :render} ->
      render.(assigns)

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, page_title: "Form2")
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, state} ->
    render.(state)

  {:event, socket, state, _event, _params} ->
    {socket, state}

  {:info, socket, state, _event} ->
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view("/form2", handler)

handler = fn
  {:mount, socket, state} ->
    socket = assign(socket, applet_css: "/applets/flex3.css")
    socket = assign(socket, applet_js: "/applets/flex3.js")
    socket = assign(socket, page_title: "Forms")
    {socket, state}

  {:params, socket, state, _params, _uri} ->
    {socket, state}

  {:render, _assigns, assigns} ->
    ~H"""
    <div class="flex h-screen w-full">
      <iframe src="/form1" class="w-1/2 h-full border-none"></iframe>
      <iframe src="/form2" class="w-1/2 h-full border-none"></iframe>
    </div>
    """

  {:event, socket, state, _event, _params} ->
    {socket, state}

  {:info, socket, state, _event} ->
    {socket, state}

  {:close, _socket, _state, _reason} ->
    :ok
end

Terminal.view("/", handler)

:ok
