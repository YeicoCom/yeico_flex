defmodule Flex.LiveScreen do
  use Flex.Service
  use Terminal.Live

  # Adb is the global transient state
  # @shared is immutable state merging screen environ and screen config
  # widgets don't perform logic
  # widgets don't actively share screen wide state
  # widgets share global state through Api.putcast!
  # screen pools points and timers together
  # valid sources are:
  #   {const_name, {:const, fixed_value}}
  #   {point_name, {:point, adb_point_key}}
  #   {timer_name, {:timer, period_in_ms}}
  #   {shared_name, {:shared, shared_key}}

  defp specs(),
    do: %{
      auth: %{initial: nil, check: :map?},
      pass: %{initial: nil, check: {:fun?, 0}},
      path: %{initial: nil, check: :binary},
      barco: %{initial: nil, check: :binary?},
      title: %{initial: nil, check: :binary},
      theme: %{initial: nil, check: :binary?},
      width: %{initial: nil, check: {:integer, 1, 65_535}},
      height: %{initial: nil, check: {:integer, 1, 65_535}},
      style: %{initial: nil, check: :binary?},
      class: %{initial: %{}, check: :map},
      shared: %{initial: %{}, check: :map},
      favicon: %{initial: nil, check: :binary?},
      applet: %{initial: "flex3", check: :binary},
      suffix: %{initial: " · Flex", check: :binary?},
      keypad: %{initial: fn _ -> false end, check: {:fun, 1}},
      widgets: %{initial: [], check: {:list, nil, &check(&1, &2, :widget)}}
    }

  def add(config = %{widgets: widgets}, pos, mod, opts \\ [])
      when is_tuple(pos) and is_atom(mod) and is_list(opts) do
    widgets = [widgets, {pos, mod, mod.new(opts), Api.wrapper()}] |> List.flatten()
    %{config | widgets: widgets}
  end

  defp name(%{path: path}),
    do: "live-screen:#{path}"

  defp setup(config = %{path: path, auth: auth}) do
    sid = name(config)
    Log.debug("#{sid} run")
    # handler gets auto wrapped
    Terminal.view(path, handler(sid, config), auth: auth)
    Api.receive()
    exit(:kill)
  end

  defp handler(sid, config = %{widgets: widgets}) do
    widgets =
      for {{pos, mod, config, wrapper}, index} <- widgets |> Enum.with_index(), into: %{} do
        %{handler: handler, inputs: inputs} = mod.build(config)
        handler = wrap(handler, wrapper, Function.info(handler, :module))
        {index, %{pos: pos, handler: handler, inputs: inputs}}
      end

    fn
      {:mount, socket = %{assigns: assigns}, state} ->
        %{connected?: connected?, tzoffset: tzoffset, localhost?: localhost?} = assigns
        %{title: title, style: style, width: width, height: height, applet: applet} = config
        %{class: class, pass: pass, suffix: suffix, favicon: favicon} = config
        %{shared: shared, barco: barco, keypad: keypad, theme: theme} = config
        keypad? = keypad.(localhost?)
        socket = assign(socket, applet_css: "/applets/#{applet}.css")
        socket = assign(socket, applet_js: "/applets/#{applet}.js")
        socket = assign(socket, applet_args: %{barco: barco})
        socket = assign(socket, favicon_url: favicon)
        socket = assign(socket, page_suffix: suffix)
        socket = assign(socket, page_title: title)
        shared = Map.put_new(shared, :keypad?, keypad?)
        shared = Map.put_new(shared, :localhost?, localhost?)
        shared = Map.put_new(shared, :connected?, connected?)
        shared = Map.put_new(shared, :tzoffset, tzoffset)
        shared = Map.put_new(shared, :title, title)
        shared = Map.put_new(shared, :width, width)
        shared = Map.put_new(shared, :height, height)
        shared = Map.put_new(shared, :class, class)
        shared = Map.put_new(shared, :pass, pass)
        state = Map.put(state, :keypad?, keypad?)
        state = Map.put(state, :style, style)
        state = Map.put(state, :theme, theme)
        state = Map.put(state, :pass, pass)
        state = Map.put(state, :size, nil)
        state = Map.put(state, :width, width)
        state = Map.put(state, :height, height)
        state = Map.put(state, :modal, nil)
        state = Map.put(state, :count, map_size(widgets))
        state = mount(sid, state, shared, widgets)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state = %{pass: nil}} ->
        %{widgets: widgets, count: count, size: size} = state

        index =
          for i <- 0..(count - 1)//1 do
            {i, widgets[i]}
          end

        %{width: ew, height: eh} = state

        {x, y, w, h, s} =
          case size do
            nil ->
              {nil, nil, nil, nil, nil}

            {rw, rh} ->
              s = min(rw / ew, rh / eh)
              cw = ew * s
              ch = eh * s
              x = (rw - cw) / 2
              y = (rh - ch) / 2
              {x, y, cw, ch, s}
          end

        state = Map.put(state, :index, index)
        state = Map.put(state, :s, s)
        state = Map.put(state, :w, w)
        state = Map.put(state, :h, h)
        state = Map.put(state, :x, x)
        state = Map.put(state, :y, y)
        render(state)

      {:render, _assigns, state} ->
        login(state)

      # pass index to get the event callback
      {:event, socket, state = %{modal: modal}, "modal:close", params = %{"index" => index}} ->
        index = String.to_integer(index)
        state = call(state, index, fn ctx -> Map.put(ctx, :event, {:close, modal, params}) end)
        state = Map.put(state, :modal, nil)
        {socket, state}

      # close despite missing index
      {:event, socket, state, "modal:close", _params} ->
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, "hook:resize", %{"width" => width, "height" => height}} ->
        state = Map.put(state, :size, {width, height})
        {socket, state}

      {:event, socket, state = %{pass: pass}, "login:pass", params} ->
        state = Map.put(state, :pass, if(pass.() == params["pass"], do: nil, else: pass))
        {socket, state}

      # for phx-click and the like
      {:event, socket, state, event, params = %{"index" => index}} ->
        index = String.to_integer(index)
        state = call(state, index, fn ctx -> Map.put(ctx, :event, {:event, event, params}) end)
        {socket, state}

      {:event, socket, state, _event, _params} ->
        {socket, state}

      {:info, socket, state, {:timer, index, name, ms}} ->
        Process.send_after(self(), {:timer, index, name, ms}, ms)

        state =
          call(state, index, fn ctx = %{inputs: inputs} ->
            ctx
            |> Map.put(:inputs, Map.update(inputs, name, 1, &(&1 + 1)))
            |> Map.put(:event, {:timer, name})
          end)

        {socket, state}

      {:info, socket, state, {_point, {:point, index, name}, val}} ->
        state =
          call(state, index, fn ctx = %{inputs: inputs} ->
            ctx
            |> Map.put(:inputs, Map.put(inputs, name, val))
            |> Map.put(:event, {:point, name})
          end)

        {socket, state}

      {:info, socket, state, {:modal, modal = %{handler: handler, props: props, index: index}}}
      when is_function(handler, 1) and is_map(props) and is_integer(index) ->
        state = Map.put(state, :modal, modal)
        {socket, state}

      {:info, socket, state, {:modal, nil}} ->
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:info, socket, state, _event} ->
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end

  defp mount(sid, state, shared, widgets) do
    self = self()

    widgets =
      for {index, %{pos: pos, handler: handler, inputs: inputs}} <- widgets, into: %{} do
        wid = "#{sid}:widget:#{index}"

        log = fn level, term ->
          Api.log(level, "#{wid} #{Api.inspect?(term)}")
        end

        # to access shared declare an input
        ctx =
          %{
            log: log,
            wid: wid,
            pos: pos,
            state: %{},
            index: index,
            event: :mount,
            inputs: Flex.Reactor.init(index, inputs, shared),
            modal: &send(self, {:modal, if(&1, do: Map.put(&1, :index, index), else: &1)})
          }

        ctx = Map.put(ctx, :state, handler.(ctx))
        {index, %{handler: handler, ctx: ctx}}
      end

    Map.put(state, :widgets, widgets)
  end

  defp login(assigns) do
    ~H"""
    <div id="ll_main" data-theme={@theme} class="h-screen w-screen bg-base-300"/>
    <.fui id="ll_modal" fun={&Flex.Modal.render/1} theme={@theme}>
      <form id="ll_form" phx-submit="login:pass" phx-update="ignore"
        class="flex flex-col p-4 gap-2 items-center justify-center rounded">
        <div id="ll_label" class="select-none">Password</div>
        <input id="ll_input" name="pass" type="password" size="24" phx-hook="Focus"
          class="daisy-input daisy-input-bordered w-full text-center">
        <.fui :if={@keypad?} fun={&Flex.Keypad.render/1} input="ll_input"/>
      </form>
    </.fui>
    <style :if={@style}><%= raw(@style) %></style>
    """
  end

  defp render(assigns) do
    ~H"""
    <div id="ls_main" data-theme={@theme} inert={!!@modal} phx-hook="Resize" phx-window-keydown="modal:close" phx-key="Escape" phx-value-index={@modal[:index]}
      class="relative h-screen w-screen overflow-hidden select-none text-base outline-none border-box leading-none text-nowrap bg-base-300">
      <div :if={@size} id="ls_panel" class="absolute bg-base-100 text-base-content" style={"left:#{@x}px;top:#{@y}px;width:#{@w}px;height:#{@h}px;"}>
        <div class="absolute" style={"scale:#{@s};"}>
          <div :for={{index, %{handler: handler, ctx: ctx = %{pos: {x, y}}}} <- @index} id={"ls_fun#{index}"} class="ls_fun absolute" style={"left:#{x}px;top:#{y}px;"}>
            <.fui fun={fn _ -> handler.(Map.put(ctx, :event, :render)) end}/>
          </div>
        </div>
      </div>
    </div>
    <.fui id="ls_modal" fun={&Flex.Modal.render/1} :if={@modal} {@modal.props} index={@modal.index} theme={@theme}>
        <.fui fun={@modal.handler} index={@modal.index}/>
    </.fui>
    <style :if={@style}><%= raw(@style) %></style>
    """
  end

  defp call(state = %{widgets: widgets}, index, mutate) when is_function(mutate, 1) do
    Map.put(state, :widgets, call(widgets, index, mutate))
  end

  defp call(widgets, index, mutate) when is_function(mutate, 1) do
    %{handler: handler, ctx: ctx} = widgets[index]
    ctx = mutate.(ctx)
    ctx = Map.put(ctx, :state, handler.(ctx))
    put_in(widgets, [index, :ctx], ctx)
  end

  # logging and stacktraces confirmed to work with tryout/screen1.exs
  # capture wrapper at fun definition for proper stacktraces
  # it is imposible to anticipated from what context fun will be called
  # wrap required for logs and stacktraces
  # Api.wrap logs unhandled exceptions
  # Flex.wrap / Api.wrapper() does not
  defp wrap(handler, wrapper, type) do
    # Log.warn requires wrapped environment as well
    handler = fn ctx ->
      case Applet.Utils.safe(handler, ctx) do
        {:ok, result} ->
          result

        {:error, error} ->
          %{wid: wid, event: event, inputs: inputs, state: state} = ctx
          environ = [event: event, inputs: inputs, state: state]
          Log.warn("#{wid} #{Api.inspect?(environ)} rescue: #{Api.inspect?(error)}")
          exit(:kill)
      end
    end

    case type do
      {:module, :erl_eval} -> Flex.wrap(handler, wrapper)
      _ -> handler
    end
  end

  defp check(path, value, :widget) do
    Flex.Check.check(path, value, {:tuple, 4})
    {pos, mod, config, wrapper} = value
    Flex.Check.check("#{path}.pos", pos, {:tuple, 2, {:integer, 0, 65_535}})
    Flex.Reactor.check("#{path}.reactor", {mod, config})
    Flex.Check.check("#{path}.wrapper", wrapper, {:fun, 1})
  end
end
