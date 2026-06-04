defmodule Flex2.LiveScreen do
  use Flex2.Entity

  def add(entity, pos, fun, args \\ []) do
    Setter.check("pos", pos, {:list, 2, {:integer, 0, 65_535}})
    Setter.check("fun", fun, {:fun, 1})
    Setter.check("args", args, {:list, nil, &check(&1, &2, :arg)})
    %{funs: funs} = entity
    funs = [{fun, pos, args} | funs]
    Map.put(entity, :funs, funs)
  end

  defp initial() do
    %{
      width: nil,
      height: nil,
      title: nil,
      style: nil,
      path: nil,
      map: nil,
      funs: []
    }
  end

  defp checks() do
    %{
      width: {:integer, 1, 65_535},
      height: {:integer, 1, 65_535},
      title: :binary?,
      style: :binary?,
      path: :binary?,
      map: :binary,
      funs: {:list, nil, &check(&1, &2, :fun)}
    }
  end

  defp start(entity = %{map: map, path: path, funs: funs}) do
    id = Entity.get(:id)
    pid = Utils.whereis(map)
    props = Map.drop(entity, [:map, :path, :funs])
    funs = funs |> Enum.reverse() |> Enum.with_index()
    if path, do: Live.view(path, wrapped(path, map, pid, funs, props, id))
    path = "/flex2/live-screen/#{id}"
    Live.view(path, wrapped(path, map, pid, funs, props, id))
    Utils.receive()
  end

  defp clean(_) do
    :nop
  end

  defp wrapped(path, map, pid, funs, props, id) do
    Async.wrap(handler(path, map, pid, funs, props, id))
  end

  defp handler(path, map, pid, funs, props, id) do
    use Flex2.Live

    fn
      {:mount, socket, state} ->
        socket = assign(socket, applet_css: "/applets/flex2.css")
        socket = assign(socket, applet_js: "/applets/flex2.js")
        state = %{title: title} = mount(state, map, pid, funs, props, id)
        socket = assign(socket, page_title: title)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state = %{map: map, index: index, size: size}} ->
        index =
          for {index, pos} <- index do
            {map[index], index, pos}
          end

        %{width: ew, height: eh} = props

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

      {:event, socket, vstate = %{map: map}, event, params = %{"index" => index}} ->
        index = String.to_integer(index)
        {fun, ctx, index, inputs, state} = map[index]
        state = safe(fun, ctx.(index, inputs, state, {:event, event, params}, nil), index, state)
        vstate = put_in(vstate, [:map, index], {fun, ctx, index, inputs, state})
        {socket, vstate}

      {:event, socket, state, "hook:resize", %{"width" => width, "height" => height}} ->
        state = Map.put(state, :size, {width, height})
        {socket, state}

      {:event, socket, state, event, params} ->
        Log.trace(view: path, event: event, params: params)
        {socket, state}

      {:info, socket, vstate = %{map: map}, {:timer, index, arg, ms}} ->
        Process.send_after(self(), {:timer, index, arg, ms}, ms)
        {fun, ctx, index, inputs, state} = map[index]
        inputs = Map.update(inputs, arg, 1, &(&1 + 1))
        state = safe(fun, ctx.(index, inputs, state, {:timer, arg}, nil), index, state)
        vstate = put_in(vstate, [:map, index], {fun, ctx, index, inputs, state})
        {socket, vstate}

      {:info, socket, vstate = %{map: map},
       {{Flex2.ObservableMap, _name, _point}, {index, arg}, val}} ->
        {fun, ctx, index, inputs, state} = map[index]
        inputs = Map.put(inputs, arg, val)
        state = safe(fun, ctx.(index, inputs, state, {:point, arg}, nil), index, state)
        vstate = put_in(vstate, [:map, index], {fun, ctx, index, inputs, state})
        {socket, vstate}

      {:info, socket, state, event} ->
        Log.trace(view: path, info: event)
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end

  defp safe(fun, ctx = %{event: event}, index, state) do
    try do
      fun.(ctx)
    rescue
      error in RuntimeError ->
        Log.error("fun:#{index} #{Log.inspect?(event)} rescue: #{Log.inspect?(error.message)}")
        state

      error ->
        Log.error("fun:#{index} #{Log.inspect?(event)} rescue: #{Log.inspect?(error)}")
        state
    catch
      error ->
        Log.error("fun:#{index} #{Log.inspect?(event)} catch: #{Log.inspect?(error)}")
        state
    end
  end

  defp mount(state, map, pid, funs, %{title: title, style: style}, id) do
    ctx = fn index, inputs, state, event, assigns ->
      log = fn level, term ->
        Log.log(level, "fun:#{index} #{Log.inspect?(term)}")
      end

      %{
        state: state,
        event: event,
        index: index,
        inputs: inputs,
        assigns: assigns,
        trace: &log.(:trace, &1),
        debug: &log.(:debug, &1),
        info: &log.(:info, &1),
        warn: &log.(:warn, &1),
        error: &log.(:error, &1),
        put: &Flex2.ObservableMap.put(pid, &1, &2)
      }
    end

    map =
      for {{fun, _pos, args}, index} <- funs do
        inputs = setup(map, pid, index, args)
        state = safe(fun, ctx.(index, inputs, state, :mount, nil), index, %{})
        {index, {fun, ctx, index, inputs, state}}
      end
      |> Enum.into(%{})

    index =
      for {{_fun, pos, _args}, index} <- funs do
        {index, pos}
      end

    state = Map.put(state, :title, title || "Live Screen")
    # wrapper to enable logging on render event
    state = Map.put(state, :wrapper, Applet.Api.wrapper())
    state = Map.put(state, :prefix, "live_screen_#{id}")
    state = Map.put(state, :style, style)
    state = Map.put(state, :index, index)
    state = Map.put(state, :size, nil)
    state = Map.put(state, :map, map)
    state = Map.put(state, :pid, pid)
    state
  end

  defp render(assigns) do
    use Flex2.Live

    ~H"""
    <div id={@prefix} phx-hook="Resize"
      class="live_screen relative h-screen w-screen select-none text-base [&_*]:cursor-default text-white bg-black outline-none border-box leading-none text-nowrap">
      <div :if={@size} class="absolute" style={"left:#{@x}px;top:#{@y}px;width:#{@w}px;height:#{@h}px;"}>
        <div class="absolute" style={"scale:#{@s};"}>
          <div :for={{fun, index, [x, y]} <- @index} id={"#{@prefix}_fun#{index}"} class="absolute" style={"left:#{x}px;top:#{y}px;"}>
            <.fui fun={@wrapper.(fun(fun))}/>
          </div>
        </div>
      </div>
    </div>
    <style>
      @scope { .live_screen { <%= @style %> }}
    </style>
    """
  end

  defp fun({fun, ctx, index, inputs, state}) do
    fn _ ->
      try do
        fun.(ctx.(index, inputs, state, :render, %{index: index}))
      rescue
        error in RuntimeError ->
          Log.error("fun:#{index} render rescue: #{Log.inspect?(error.message)}")
          error(%{error: error})

        error ->
          Log.error("fun:#{index} render rescue: #{Log.inspect?(error)}")
          error(%{error: error})
      catch
        error ->
          Log.error("fun:#{index} render catch: #{Log.inspect?(error)}")
          error(%{error: error})
      end
    end
  end

  defp error(assigns) do
    use Flex2.Live
    ~H""
  end

  defp setup(map, pid, index, args) do
    for {arg, spec} <- args, reduce: %{} do
      inputs ->
        case spec do
          {:const, const} ->
            Map.put(inputs, arg, const)

          {:point, point} ->
            Flex2.ObservableMap.subscribe!(map, point, {index, arg})
            val = Flex2.ObservableMap.get(pid, point)
            Map.put(inputs, arg, val)

          {:timer, ms} ->
            Process.send_after(self(), {:timer, index, arg, ms}, ms)
            Map.put(inputs, arg, 0)
        end
    end
  end

  defp check(name, value, :fun) do
    case value do
      {fun, pos, args} ->
        Setter.check("#{name}:fun", fun, {:fun, 1})
        Setter.check("pos", pos, {:list, 2, {:integer, 0, 65_535}})
        Setter.check("#{name}:args", args, {:list, nil, &check(&1, &2, :arg)})

      _ ->
        Setter.abort(name, value, "invalid fun")
    end
  end

  defp check(name, value, :arg) do
    case value do
      {key, value} ->
        Setter.check(name, key, :atom)

        case value do
          {:timer, value} -> Setter.check("#{name}:timer", value, {:integer, 1, 65_535})
          {:point, value} -> Setter.check("#{name}:point", value, :binary)
          {:const, _value} -> :ok
          _ -> Setter.abort(name, value, "invalid arg")
        end

      _ ->
        Setter.abort(name, value, "invalid arg")
    end
  end
end
