defmodule Flex.LiveScreen do
  use Flex.Service
  use Terminal.Live

  defp initial(),
    do: %{
      auth: nil,
      pass: nil,
      path: nil,
      barco: nil,
      title: nil,
      width: nil,
      height: nil,
      style: nil,
      class: %{},
      global: %{},
      shared: %{},
      favicon: nil,
      theme: nil,
      applet: "flex3",
      suffix: " · Flex",
      keypad: fn _ -> false end,
      funs: []
    }

  defp checks(),
    do: %{
      auth: :map?,
      pass: {:fun?, 0},
      barco: :binary?,
      class: :map,
      global: :map,
      shared: :map,
      path: :binary,
      title: :binary,
      theme: :binary?,
      applet: :binary,
      style: :binary?,
      suffix: :binary?,
      favicon: :binary?,
      keypad: {:fun, 1},
      width: {:integer, 1, 65_535},
      height: {:integer, 1, 65_535},
      funs: {:list, nil, &check(&1, &2, :fun)}
    }

  def add(config = %{class: class}, :class, key, value)
      when is_binary(key) and is_binary(value) do
    Check.check("add:class:key", key, :binary)
    Check.check("class[#{key}]", value, :binary)
    put_in(config, [:class, key], [class[key] || [], value] |> List.flatten())
  end

  def add(config = %{funs: funs}, pos, args, fun)
      when is_tuple(pos) and is_list(args) and is_function(fun, 1) do
    check("add:fun", {pos, args, fun}, :fun)
    fun = wrap(fun, Function.info(fun, :module))
    funs = [funs, {pos, args, fun}] |> List.flatten()
    Map.put(config, :funs, funs)
  end

  def add(config, pos, mod, opts) when is_tuple(pos) and is_atom(mod) and is_list(opts),
    do: add(config, {pos, opts |> mod.new() |> mod.fun()})

  def add(config, pos, mod) when is_tuple(pos) and is_atom(mod), do: add(config, pos, mod, [])

  def add(config, pos, fun) when is_tuple(pos) and is_function(fun, 1),
    do: add(config, pos, [], fun)

  def add(config, {pos, {args, fun}}), do: add(config, pos, args, fun)

  def reduce(config, enum, fun) when is_function(fun, 2) do
    for e <- enum, reduce: config do
      config -> fun.(config, e)
    end
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

  defp handler(sid, config = %{applet: applet}) do
    fn
      {:mount, socket = %{assigns: assigns}, state} ->
        %{connected?: connected?, tzoffset: tzoffset, localhost?: localhost?} = assigns
        %{title: title, style: style, width: width, height: height, keypad: keypad} = config
        %{class: class, pass: pass, suffix: suffix, favicon: favicon, theme: theme} = config
        %{global: global, shared: shared, barco: barco} = config
        socket = assign(socket, applet_css: "/applets/#{applet}.css")
        socket = assign(socket, applet_js: "/applets/#{applet}.js")
        socket = assign(socket, applet_args: %{barco: barco})
        socket = assign(socket, favicon_url: favicon)
        socket = assign(socket, page_suffix: suffix)
        socket = assign(socket, page_title: title)
        state = Map.put(state, :style, style)
        state = Map.put(state, :theme, theme)
        state = Map.put(state, :pass, pass)
        state = Map.put(state, :size, nil)
        global = Map.put(global, :keypad?, keypad.(localhost?))
        global = Map.put(global, :localhost?, localhost?)
        global = Map.put(global, :connected?, connected?)
        global = Map.put(global, :tzoffset, tzoffset)
        global = Map.put(global, :title, title)
        global = Map.put(global, :width, width)
        global = Map.put(global, :height, height)
        global = Map.put(global, :class, class)
        global = Map.put(global, :pass, pass)
        state = Map.put(state, :global, global)
        state = Map.put(state, :shared, shared)
        state = Map.put(state, :modal, nil)
        state = mount(state, sid, config)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state = %{pass: nil}} ->
        %{map: map, count: count, size: size, global: global} = state

        index =
          for i <- 0..(count - 1)//1 do
            {i, map[i]}
          end

        %{width: ew, height: eh} = global

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

      {:event, socket, state, event, params = %{"index" => index}} ->
        index = String.to_integer(index)
        state = call(state, index, fn ctx -> Map.put(ctx, :event, {:event, event, params}) end)
        {socket, state}

      {:event, socket, state, _event, _params} ->
        {socket, state}

      {:info, socket, state, {:timer, index, arg, ms}} ->
        Process.send_after(self(), {:timer, index, arg, ms}, ms)

        state =
          call(state, index, fn ctx = %{inputs: inputs} ->
            ctx
            |> Map.put(:inputs, Map.update(inputs, arg, 1, &(&1 + 1)))
            |> Map.put(:event, {:timer, arg})
          end)

        {socket, state}

      {:info, socket, state, {_point, {:point, index, arg}, val}} ->
        state =
          call(state, index, fn ctx = %{inputs: inputs} ->
            ctx
            |> Map.put(:inputs, Map.put(inputs, arg, val))
            |> Map.put(:event, {:point, arg})
          end)

        {socket, state}

      {:info, socket, state = %{map: map, count: count, shared: shared}, {:shared, event, fun}}
      when is_function(fun, 1) ->
        {changed?, shared} = update(shared, fun)
        state = Map.put(state, :shared, shared)
        count = if(changed?, do: count, else: 0)

        map =
          for index <- 0..(count - 1)//1, reduce: map do
            map ->
              call(state, map, index, fn ctx -> Map.put(ctx, :event, {:shared, event}) end)
          end

        state = Map.put(state, :map, map)
        {socket, state}

      {:info, socket, state, {:modal, modal = %{fun: fun, props: props, index: index}}}
      when is_function(fun, 1) and is_map(props) and is_integer(index) ->
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

  defp mount(state, sid, %{funs: funs}) do
    self = self()

    map =
      for {{pos, args, fun}, index} <- Enum.with_index(funs), into: %{} do
        fid = "#{sid}:fun:#{index}"

        log = fn level, term ->
          Api.log(level, "#{fid} #{Api.inspect?(term)}")
        end

        ctx =
          %{
            fid: fid,
            pos: pos,
            index: index,
            event: :mount,
            inputs: init(index, args),
            state: %{index: index},
            trace: &log.(:trace, &1),
            debug: &log.(:debug, &1),
            info: &log.(:info, &1),
            warn: &log.(:warn, &1),
            error: &log.(:error, &1),
            modal: &send(self, {:modal, if(&1, do: Map.put(&1, :index, index), else: &1)}),
            share: &send(self, {:shared, {&1, &2}, fn shared -> Map.put(shared, &1, &2) end})
          }

        ctx = Map.put(ctx, :state, call(state, fun, ctx))
        {index, {fun, ctx}}
      end

    state = Map.put(state, :count, length(funs))
    state = Map.put(state, :map, map)
    state
  end

  defp login(assigns) do
    ~H"""
    <div id="ls_main" data-theme={@theme} class="h-screen w-screen bg-base-300"/>
    <.fui id="ls_modal" fun={&Flex.Modal.render/1} theme={@theme}>
      <form id="ll_form" phx-submit="login:pass" phx-update="ignore"
        class="flex flex-col p-4 gap-2 items-center justify-center rounded">
        <div id="ll_label" class="select-none">Password</div>
        <input id="ll_input" name="pass" type="password" size="24" phx-hook="Focus"
          class="daisy-input daisy-input-bordered w-full text-center">
        <.fui :if={@global.keypad?} fun={&Flex.Keypad.render/1} input="ll_input"/>
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
          <div :for={{index, {fun, ctx = %{pos: {x, y}}}} <- @index} id={"ls_fun#{index}"} class="ls_fun absolute" style={"left:#{x}px;top:#{y}px;"}>
            <.fui fun={fn _ -> call(%{global: @global, shared: @shared}, fun, Map.put(ctx, :event, :render)) end}/>
          </div>
        </div>
      </div>
    </div>
    <.fui id="ls_modal" fun={&Flex.Modal.render/1} :if={@modal} {@modal.props} index={@modal.index} theme={@theme}>
        <.fui fun={@modal.fun} {%{index: @modal.index, global: @global, shared: @shared}}/>
    </.fui>
    <style :if={@style}><%= raw(@style) %></style>
    """
  end

  defp call(%{global: global, shared: shared}, fun, ctx) when is_function(fun, 1) do
    fun.(Map.merge(ctx, %{global: global, shared: shared}))
  end

  defp call(state = %{map: map}, index, mutate) when is_function(mutate, 1) do
    Map.put(state, :map, call(state, map, index, mutate))
  end

  defp call(state, map, index, mutate) when is_function(mutate, 1) do
    {fun, ctx} = map[index]
    ctx = mutate.(ctx)
    ctx = Map.put(ctx, :state, call(state, fun, ctx))
    Map.put(map, index, {fun, ctx})
  end

  # logging and stacktraces confirmed to work with tryout/screen1.exs
  # capture wrapper at fun definition for proper stacktraces
  # it is imposible to anticipated from what context fun will be called
  # wrap required for logs and stacktraces
  # Api.wrap logs unhandled exceptions
  # Flex.wrap / Api.wrapper() does not
  defp wrap(fun, type) do
    # Log.warn requires wrapped environment as well
    fun = fn ctx ->
      case Applet.Utils.safe(fun, ctx) do
        {:ok, result} ->
          result

        {:error, error} ->
          %{global: global, shared: shared} = ctx
          %{fid: fid, event: event, inputs: inputs, state: state} = ctx
          environ = [event: event, inputs: inputs, state: state, global: global, shared: shared]
          Log.warn("#{fid} #{Api.inspect?(environ)} rescue: #{Api.inspect?(error)}")
          exit(:kill)
      end
    end

    case type do
      {:module, :erl_eval} -> Flex.wrap(fun)
      _ -> fun
    end
  end

  defp update(shared, fun) do
    new = fun.(shared)
    {new != shared, new}
  end

  defp init(index, args) do
    for {arg, spec} <- args, reduce: %{} do
      inputs ->
        case spec do
          {:const, const} ->
            Map.put(inputs, arg, const)

          {:point, key} ->
            val = Api.subget!(key, sarg: {:point, index, arg}, defv: nil)
            Map.put(inputs, arg, val)

          {:timer, ms} ->
            Process.send_after(self(), {:timer, index, arg, ms}, ms)
            Map.put(inputs, arg, 0)
        end
    end
  end

  defp check(name, value, :fun) do
    case value do
      {pos, args, fun} ->
        Check.check("#{name}.pos", pos, {:tuple, 2, {:integer, 0, 65_535}})
        Check.check("#{name}.args", args, {:list, nil, &check(&1, &2, :arg)})
        Check.check("#{name}.fun", fun, {:fun, 1})

      _ ->
        Check.abort(name, value, "invalid fun")
    end
  end

  defp check(name, value, :arg) do
    case value do
      {key, value} ->
        Check.check(name, key, :atom)

        case value do
          {:timer, ms} -> Check.check("#{name}.timer", ms, {:integer, 1, 65_535})
          {:point, key} -> Check.check("#{name}.point", key, :any)
          {:const, _value} -> :ok
          _ -> Check.abort(name, value, "invalid arg")
        end

      _ ->
        Check.abort(name, value, "invalid arg")
    end
  end
end
