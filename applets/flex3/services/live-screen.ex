defmodule Flex.LiveScreen do
  use Flex.Service
  use Terminal

  defp initial() do
    %{
      pass: nil,
      path: nil,
      title: nil,
      width: nil,
      height: nil,
      style: nil,
      class: %{},
      global: %{},
      shared: %{},
      favicon: nil,
      suffix: " · Flex",
      funs: []
    }
  end

  defp checks() do
    %{
      pass: {:fun?, 0},
      class: :map,
      global: :map,
      shared: :map,
      path: :binary,
      title: :binary,
      style: :binary?,
      suffix: :binary?,
      favicon: :binary?,
      width: {:integer, 1, 65_535},
      height: {:integer, 1, 65_535},
      funs: {:list, nil, &check(&1, &2, :fun)}
    }
  end

  def add(config, {pos, fun}), do: add(config, pos, fun, [])
  def add(config, {pos, fun, args}), do: add(config, pos, fun, args)

  def add(config = %{funs: funs}, pos, fun, args \\ []) do
    Check.check("pos", pos, {:list, 2, {:integer, 0, 65_535}})
    Check.check("fun", fun, {:fun, 1})
    Check.check("args", args, {:list, nil, &check(&1, &2, :arg)})
    fun = wrap(fun, Function.info(fun, :module))
    funs = [{pos, fun, args} | funs] |> Enum.reverse()
    Map.put(config, :funs, funs)
  end

  def put(config, :class, key, value) when is_binary(key) and is_list(value) do
    Check.check("class[#{key}]", value, {:list, nil, :binary})
    put_in(config, [:class, key], value)
  end

  def put(config, :class, key, value) when is_binary(key) do
    Check.check("class[#{key}]", value, :binary)
    put_in(config, [:class, key], value)
  end

  # log confirmed to work in render callback
  # Api.wrap logs unhandled exceptions
  # Api.wrapper() does not
  defp wrap(fun, {:module, :erl_eval}), do: Api.wrapper().(fun)
  defp wrap(fun, _), do: fun

  defp name(%{path: path}),
    do: "live-screen:#{path}"

  defp setup(config = %{path: path}) do
    sid = name(config)
    Log.debug("#{sid} run")
    wrapped = Api.wrapper().(handler(sid, config))
    Terminal.view(path, wrapped)
    Api.receive()
    exit(:kill)
  end

  defp handler(sid, config = %{path: path}) do
    use Terminal.Live

    fn
      {:mount, socket = %{assigns: %{connected?: connected?, tzoffset: tzoffset}}, state} ->
        %{title: title, style: style, width: width, height: height} = config
        %{class: class, pass: pass, suffix: suffix, favicon: favicon} = config
        %{global: global, shared: shared} = config
        socket = assign(socket, applet_css: "/applets/flex3.css")
        socket = assign(socket, applet_js: "/applets/flex3.js")
        socket = assign(socket, favicon_url: favicon)
        socket = assign(socket, page_suffix: suffix)
        socket = assign(socket, page_title: title)
        state = Map.put(state, :style, style)
        state = Map.put(state, :width, width)
        state = Map.put(state, :height, height)
        state = Map.put(state, :class, class)
        state = Map.put(state, :pass, pass)
        state = Map.put(state, :size, nil)
        global = Map.put(global, :connected?, connected?)
        global = Map.put(global, :tzoffset, tzoffset)
        global = Map.put(global, :title, title)
        global = Map.put(global, :width, width)
        global = Map.put(global, :height, height)
        global = Map.put(global, :class, class)
        state = Map.put(state, :global, global)
        state = Map.put(state, :shared, shared)
        state = mount(state, sid, config)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state = %{map: map, count: count, pass: nil}} ->
        index =
          for i <- 0..(count - 1)//1 do
            {i, map[i]}
          end

        %{width: ew, height: eh, size: size} = state

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

      {:event, socket, state = %{map: map}, event, params = %{"index" => index}} ->
        index = String.to_integer(index)
        {fun, ctx} = map[index]
        ctx = Map.merge(ctx, %{event: {:event, event, params}})
        ctx = Map.merge(ctx, %{state: call!(state, fun, ctx)})
        state = put_in(state, [:map, index], {fun, ctx})
        {socket, state}

      {:event, socket, state, event = "hook:resize",
       params = %{"width" => width, "height" => height}} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :size, {width, height})
        {socket, state}

      {:event, socket, state = %{pass: pass}, event = "login:pass", params} ->
        Log.trace(view: path, event: event, params: params)
        state = Map.put(state, :pass, if(pass.() == params["pass"], do: nil, else: pass))
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, state = %{map: map}, {:timer, index, arg, ms}} ->
        Process.send_after(self(), {:timer, index, arg, ms}, ms)
        {fun, ctx = %{inputs: inputs}} = map[index]
        inputs = Map.update(inputs, arg, 1, &(&1 + 1))
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:timer, arg}})
        ctx = Map.merge(ctx, %{state: call!(state, fun, ctx)})
        state = put_in(state, [:map, index], {fun, ctx})
        {socket, state}

      {:info, socket, state = %{map: map}, {point, {index, arg}, val}} when is_binary(point) ->
        {fun, ctx = %{inputs: inputs}} = map[index]
        inputs = Map.put(inputs, arg, val)
        ctx = Map.merge(ctx, %{inputs: inputs, event: {:point, arg}})
        ctx = Map.merge(ctx, %{state: call!(state, fun, ctx)})
        state = put_in(state, [:map, index], {fun, ctx})
        {socket, state}

      {:info, socket, state = %{map: map, count: count, shared: shared}, {:shared, event, fun}}
      when is_function(fun, 1) ->
        {changed?, shared} = mutate(shared, fun)
        state = Map.put(state, :shared, shared)
        count = if(changed?, do: count, else: 0)

        map =
          for index <- 0..(count - 1)//1, reduce: map do
            map ->
              {fun, ctx} = map[index]
              ctx = Map.merge(ctx, %{event: {:shared, event}})
              ctx = Map.merge(ctx, %{state: call!(state, fun, ctx)})
              Map.put(map, index, {fun, ctx})
          end

        state = Map.put(state, :map, map)
        {socket, state}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, reason} ->
        Log.trace(view: path, close: reason)
        :ok
    end
  end

  defp mount(state, sid, %{funs: funs}) do
    self = self()

    map =
      for {{pos, fun, args}, index} <- Enum.with_index(funs), into: %{} do
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
            put: &send(self, {:shared, {:put, &1, &2}, fn shared -> Map.put(shared, &1, &2) end})
          }

        ctx = Map.merge(ctx, %{state: call!(state, fun, ctx)})
        {index, {fun, ctx}}
      end

    # wrapper to enable logging on render event
    state = Map.put(state, :wrapper, Applet.Api.wrapper())
    state = Map.put(state, :count, length(funs))
    state = Map.put(state, :map, map)
    state
  end

  defp render(assigns) do
    use Terminal.Live

    ~H"""
    <div id="ls_main" phx-hook="Resize"
      class={["relative h-screen w-screen", @class["ls:main"] || "select-none text-base [&_*]:cursor-default text-white bg-black outline-none border-box leading-none text-nowrap"]}>
      <div :if={@size} id="ls_panel" class={["absolute", @class["ls:panel"]]} style={"left:#{@x}px;top:#{@y}px;width:#{@w}px;height:#{@h}px;"}>
        <div class="absolute" style={"scale:#{@s};"}>
          <div :for={{index, {fun, ctx = %{pos: [x, y]}}} <- @index} id={"fun#{index}"} class={["absolute", @class["ls:fun"]]} style={"left:#{x}px;top:#{y}px;"}>
            <.fui fun={fn _ -> call!(%{global: @global, shared: @shared}, fun, Map.merge(ctx, %{event: :render})) end}/>
          </div>
        </div>
      </div>
    </div>
    <style :if={@style}><%= raw(@style) %></style>
    """
  end

  defp login(assigns) do
    use Terminal.Live

    ~H"""
    <form id="ll_form" class={@class["ll:form"] || "h-screen w-screen text-white flex flex-col gap-4 items-center justify-center"} phx-submit="login:pass">
      <label id="ll_label" for="ll_input" class={@class["ll:label"] || "text-3xl uppercase"}>Password</label>
      <input id="ll_input" name="pass" type="password" size="16" phx-hook="AutoFocus"
        class={@class["ll:input"] || "text-3xl text-center outline-none border-0 ring-0 bg-zinc-600 rounded-lg focus:ring-lime-500"}>
    </form>
    <style :if={@style}><%= raw(@style) %></style>
    """
  end

  defp call!(%{global: global, shared: shared}, fun, ctx) do
    %{fid: fid, event: event, inputs: inputs, state: state} = ctx
    environ = [event: event, inputs: inputs, state: state]
    ctx = Map.merge(ctx, %{global: global, shared: shared})

    # Api.safe logs unhandled exceptions
    # confirmed that stacktraces report the script file and line number
    case Applet.Utils.safe(fun, ctx) do
      {:ok, state} ->
        state

      {:error, error} ->
        Log.warn("#{fid} #{Api.inspect?(environ)} rescue: #{Api.inspect?(error)}")
        exit(:kill)
    end
  end

  defp mutate(shared, fun) do
    new = fun.(shared)
    {new != shared, new}
  end

  defp init(index, args) do
    for {arg, spec} <- args, reduce: %{} do
      inputs ->
        case spec do
          {:const, const} ->
            Map.put(inputs, arg, const)

          {:point, point} ->
            val = Api.subget!(point, sarg: {index, arg}, defv: nil)
            Map.put(inputs, arg, val)

          {:timer, ms} ->
            Process.send_after(self(), {:timer, index, arg, ms}, ms)
            Map.put(inputs, arg, 0)
        end
    end
  end

  defp check(name, value, :fun) do
    case value do
      {pos, fun, args} ->
        Check.check("#{name}:fun", fun, {:fun, 1})
        Check.check("pos", pos, {:list, 2, {:integer, 0, 65_535}})
        Check.check("#{name}:args", args, {:list, nil, &check(&1, &2, :arg)})

      _ ->
        Check.abort(name, value, "invalid fun")
    end
  end

  defp check(name, value, :arg) do
    case value do
      {key, value} ->
        Check.check(name, key, :atom)

        case value do
          {:timer, value} -> Check.check("#{name}:timer", value, {:integer, 1, 65_535})
          {:point, value} -> Check.check("#{name}:point", value, :binary)
          {:const, _value} -> :ok
          _ -> Check.abort(name, value, "invalid arg")
        end

      _ ->
        Check.abort(name, value, "invalid arg")
    end
  end
end
