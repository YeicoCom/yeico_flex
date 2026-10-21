defmodule Flex.MovingAnalogIndicator do
  use Flex.Reactor
  use Terminal.Live

  defp specs,
    do: %{
      value: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      visible: %{initial: nil, check: &Flex.Check.check(&1, &2, :source?)},
      bar: %{initial: {40, 120}, check: {:tuple, 2, {:integer, 0, 65_535}}},
      range: %{initial: {0.0, 10.0}, check: {:tuple, 2, :number}},
      warn: %{initial: {2.0, 6.0}, check: {:tuple, 2, :number?}},
      error: %{initial: {1.0, 8.0}, check: {:tuple, 2, :number?}},
      visible?: %{initial: nil, check: {:fun?, 1}},
      rounded?: %{initial: false, check: :boolean},
      border?: %{initial: false, check: :boolean},
      cast: %{initial: nil, check: {:fun?, 1}}
    }

  defp inputs(%{value: nil, visible: nil}), do: []
  defp inputs(%{value: value, visible: nil}), do: [{:value, value}]
  defp inputs(%{value: nil, visible: visible}), do: [{:visible, visible}]
  defp inputs(%{value: value, visible: visible}), do: [{:value, value}, {:visible, visible}]

  defp handler(%{
         bar: {bw, bh},
         range: {rl, ru},
         warn: {wl, wu},
         error: {el, eu},
         value: value,
         visible: visible,
         visible?: visible?,
         rounded?: rounded?,
         border?: border?,
         cast: cast
       }) do
    ol = wl || el || rl
    ou = wu || eu || ru
    oc = (ol + ou) / 2.0
    os = (ou - ol) / 2.0

    wl = el || ol
    wu = eu || ou

    px = %{
      o: %{
        y: bh * (ol - rl) / (ru - rl),
        h: bh * (ou - ol) / (ru - rl)
      },
      w: %{
        y: bh * (wl - rl) / (ru - rl),
        h: bh * (wu - wl) / (ru - rl)
      },
      wl: %{
        y: bh * (wl - rl) / (ru - rl),
        h: bh * (oc - wl) / (ru - rl)
      },
      wu: %{
        y: bh * oc / (ru - rl),
        h: bh * (wu - oc) / (ru - rl)
      },
      el: %{
        y: bh * rl / (ru - rl),
        h: bh * (oc - rl) / (ru - rl)
      },
      eu: %{
        y: bh * oc / (ru - rl),
        h: bh * (ru - oc) / (ru - rl)
      }
    }

    assigns = %{bw: bw / 2.0, bh: bh, px: px}

    # trace needs wrapping at the bottom |> Flex.wrap()
    fn
      %{index: index, inputs: inputs, event: :render} ->
        v = Flex.Reactor.input(inputs, :value, value)
        v = if cast, do: cast.(v), else: v

        el? = v && v < wl
        eu? = v && v > wu

        wl? = v && v < ol && !el?
        wu? = v && v > ou && !eu?

        oor? = if v, do: v < rl || v > ru
        vr = if v, do: min(max(v, rl), ru)
        vy = if vr, do: bh * (vr - rl) / (ru - rl)

        vis = Flex.Reactor.input(inputs, :visible, visible)
        vis? = visible?(visible?, vis)
        id = id(index)

        assigns =
          Map.merge(assigns, %{
            id: id,
            vy: vy,
            el?: el?,
            eu?: eu?,
            wl?: wl?,
            wu?: wu?,
            oor?: oor?,
            vis?: vis?,
            sw: if(border?, do: 1, else: 0),
            rc: if(rounded?, do: bw / 10.0)
          })

        ~H"""
        <div :if={@vis?} id={@id} class="absolute" style={"width:#{2*@bw}px;height:#{@bh}px;"}>
          <div class="absolute h-full" style={"left:0px;width:#{@bw}px;"}>
            <svg :if={@vy} class="absolute" viewBox="0 0 16 16" overflow="visible" width={@bw} height={@bw} style={"bottom:#{@vy-@bw/2.0}px;"}>
              <polygon vector-effect="non-scaling-stroke" points="0,0 16,8 0,16" fill={if(@oor?, do: "#ff0000", else: "#999999")} stroke="#15395b" stroke-width={@sw}/>
            </svg>
          </div>
          <svg class="absolute h-full" viewBox={"0 0 #{@bw} #{@bh}"} overflow="visible" width={@bw} height={@bh} style={"left:#{@bw}px;width:#{@bw}px;"}>
            <g transform={"translate(0, #{@bh}) scale(1, -1)"}>
              <rect rx={@rc} ry={@rc} vector-effect="non-scaling-stroke" x="0" y="0" width={@bw} height={@bh} stroke="#15395b" stroke-width={@sw} fill="#999999"/>
              <rect rx={@rc} ry={@rc} :if={@el?} vector-effect="non-scaling-stroke" x="0" y={@px.el.y} width={@bw} height={@px.el.h} stroke="#15395b" stroke-width={@sw} fill="#ff0000"/>
              <rect rx={@rc} ry={@rc} :if={@eu?} vector-effect="non-scaling-stroke" x="0" y={@px.eu.y} width={@bw} height={@px.eu.h} stroke="#15395b" stroke-width={@sw} fill="#ff0000"/>
              <rect rx={@rc} ry={@rc} vector-effect="non-scaling-stroke" x="0" y={@px.w.y} width={@bw} height={@px.w.h} stroke="#15395b" stroke-width={@sw} fill="#bdbdbd"/>
              <rect rx={@rc} ry={@rc} :if={@wl?} vector-effect="non-scaling-stroke" x="0" y={@px.wl.y} width={@bw} height={@px.wl.h} stroke="#15395b" stroke-width={@sw} fill="#fff000"/>
              <rect rx={@rc} ry={@rc} :if={@wu?} vector-effect="non-scaling-stroke" x="0" y={@px.wu.y} width={@bw} height={@px.wu.h} stroke="#15395b" stroke-width={@sw} fill="#fff000"/>
              <rect rx={@rc} ry={@rc} vector-effect="non-scaling-stroke" x="0" y={@px.o.y} width={@bw} height={@px.o.h} stroke="#15395b" stroke-width={@sw} fill="#c2d9f4"/>
            </g>
          </svg>
        </div>
        """

      %{state: state} ->
        state
    end
  end

  defp id(index), do: "#{inspect(__MODULE__)}_#{index}"

  defp visible?(nil, visible) when is_boolean(visible), do: visible
  defp visible?(nil, _), do: true
  defp visible?(visible?, visible), do: visible?.(visible)
end
