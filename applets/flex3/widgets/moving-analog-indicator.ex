defmodule Flex.MovingAnalogIndicator do
  use Flex.Widget
  use Terminal.Live

  defp initial,
    do: %{
      value: nil,
      bar: {10, 200},
      range: {0.0, 10.0},
      warn: {2.0, 6.0},
      error: {1.0, 8.0},
      visible?: nil
    }

  defp checks,
    do: %{
      value: &check(&1, &2, :value),
      bar: {:tuple, 2, {:integer, 0, 65_535}},
      range: {:tuple, 2, :number},
      warn: {:tuple, 2, :number?},
      error: {:tuple, 2, :number?},
      visible?: {:fun?, 1}
    }

  defp args(%{value: {:point, key}}), do: [{:value, {:point, key}}]
  defp args(_), do: []

  defp handler(%{
         bar: {bw, bh},
         range: {rl, ru},
         warn: {wl, wu},
         error: {el, eu},
         value: value,
         visible?: visible?
       }) do
    ol = wl || el || rl
    ou = wu || eu || ru

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
        h: bh * (ol - wl) / (ru - rl)
      },
      wu: %{
        y: bh * ou / (ru - rl),
        h: bh * (wu - ou) / (ru - rl)
      },
      el: %{
        y: bh * rl / (ru - rl),
        h: bh * (wl - rl) / (ru - rl)
      },
      eu: %{
        y: bh * wu / (ru - rl),
        h: bh * (ru - wu) / (ru - rl)
      }
    }

    assigns = %{bw: bw, bh: bh, px: px}

    # trace needs wrapping at the bottom |> Flex.wrap()
    fn
      %{inputs: inputs, shared: shared, event: :render} ->
        v =
          case value do
            nil -> nil
            {:const, value} -> value
            {:point, _key} -> inputs[:value]
            {:shared, key} -> shared[key]
          end

        el? = v && v < wl
        eu? = v && v > wu

        wl? = v && v < ol && !el?
        wu? = v && v > ou && !eu?

        oor? = if v, do: v < rl || v > ru
        vr = if v, do: min(max(v, rl), ru)
        vy = if vr, do: bh * (vr - rl) / (ru - rl)

        vis? = visible?(visible?, shared)

        assigns =
          Map.merge(assigns, %{
            vy: vy,
            el?: el?,
            eu?: eu?,
            wl?: wl?,
            wu?: wu?,
            oor?: oor?,
            vis?: vis?
          })

        ~H"""
        <div :if={@vis?} class="absolute" style={"width:#{2*@bw}px;height:#{@bh}px;"}>
          <div class="absolute h-full" style={"left:0px;width:#{@bw}px;"}>
            <svg :if={@vy} class="absolute" viewBox="0 0 16 16" overflow="visible" width={@bw} height={@bw} style={"bottom:#{@vy-@bw/2.0}px;"}>
              <polygon vector-effect="non-scaling-stroke" points="0,0 16,8 0,16" fill={if(@oor?, do: "#ff0000", else: "#999999")} stroke="#15395b" stroke-width="1"/>
            </svg>
          </div>
          <svg class="absolute h-full" viewBox={"0 0 #{@bw} #{@bh}"} overflow="visible" width={@bw} height={@bh} style={"left:#{@bw}px;width:#{@bw}px;"}>
            <g transform={"translate(0, #{@bh}) scale(1, -1)"}>
              <rect vector-effect="non-scaling-stroke" x="0" y="0" width={@bw} height={@bh} stroke="#15395b" stroke-width="1" fill="#999999"/>
              <rect vector-effect="non-scaling-stroke" x="0" y={@px.w.y} width={@bw} height={@px.w.h} stroke="#15395b" stroke-width="1" fill="#bdbdbd"/>
              <rect vector-effect="non-scaling-stroke" x="0" y={@px.o.y} width={@bw} height={@px.o.h} stroke="#15395b" stroke-width="1" fill="#c2d9f4"/>
              <rect :if={@wl?} vector-effect="non-scaling-stroke" x="0" y={@px.wl.y} width={@bw} height={@px.wl.h} stroke="#15395b" stroke-width="1" fill="#fff000"/>
              <rect :if={@wu?} vector-effect="non-scaling-stroke" x="0" y={@px.wu.y} width={@bw} height={@px.wu.h} stroke="#15395b" stroke-width="1" fill="#fff000"/>
              <rect :if={@el?} vector-effect="non-scaling-stroke" x="0" y={@px.el.y} width={@bw} height={@px.el.h} stroke="#15395b" stroke-width="1" fill="#ff0000"/>
              <rect :if={@eu?} vector-effect="non-scaling-stroke" x="0" y={@px.eu.y} width={@bw} height={@px.eu.h} stroke="#15395b" stroke-width="1" fill="#ff0000"/>
            </g>
          </svg>
        </div>
        """

      %{state: state} ->
        state
    end
  end

  defp visible?(nil, _), do: true
  defp visible?(fun, shared), do: fun.(shared)

  defp check(name, value, :value) do
    case value do
      nil -> :ok
      {:const, value} -> Check.check("#{name}.const", value, :number?)
      {:point, key} -> Check.check("#{name}.point", key, :any)
      {:shared, key} -> Check.check("#{name}.shared", key, :atom)
      _ -> Check.abort(name, value, "invalid value")
    end
  end
end
