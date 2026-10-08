defmodule Flex.MovingAnalogIndicator do
  use Flex.Widget
  use Terminal.Live

  defp initial,
    do: %{
      value: nil,
      bar: {10, 200},
      range: {0.0, 10.0},
      warn: {2.0, 6.0},
      error: {1.0, 8.0}
    }

  defp checks,
    do: %{
      value: :number?,
      bar: {:tuple, 2, {:integer, 0, 65_535}},
      range: {:tuple, 2, :number},
      warn: {:tuple, 2, :number?},
      error: {:tuple, 2, :number?}
    }

  defp args(_config) do
    []
  end

  defp handler(%{bar: {bw, bh}, range: {rl, ru}, warn: {wl, wu}, error: {el, eu}, value: value}) do
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

    fn
      %{event: :render} ->
        el? = value && value < wl
        eu? = value && value > wu

        wl? = value && value < ol && !el?
        wu? = value && value > ou && !eu?

        vy = if value, do: bh * (value - rl) / (ru - rl)
        assigns = Map.merge(assigns, %{el?: el?, eu?: eu?, wl?: wl?, wu?: wu?, vy: vy})

        ~H"""
        <div class="absolute" style={"width:#{2*@bw}px;height:#{@bh}px;"}>
          <div class="absolute h-full bg-[#666666]" style={"left:#{@bw}px;width:#{@bw}px;"}>
            <div class="absolute bg-[#bdbdbd]" style={"bottom:#{@px.w.y}px;width:#{@bw}px;height:#{@px.w.h}px;"}></div>
            <div class="absolute bg-[#c2d9f4]" style={"bottom:#{@px.o.y}px;width:#{@bw}px;height:#{@px.o.h}px;"}></div>
            <div :if={@wl?} class="absolute bg-[#fff000]" style={"bottom:#{@px.wl.y}px;width:#{@bw}px;height:#{@px.wl.h}px;"}></div>
            <div :if={@wu?} class="absolute bg-[#fff000]" style={"bottom:#{@px.wu.y}px;width:#{@bw}px;height:#{@px.wu.h}px;"}></div>
            <div :if={@el?} class="absolute bg-[#ff0000]" style={"bottom:#{@px.el.y}px;width:#{@bw}px;height:#{@px.el.h}px;"}></div>
            <div :if={@eu?} class="absolute bg-[#ff0000]" style={"bottom:#{@px.eu.y}px;width:#{@bw}px;height:#{@px.eu.h}px;"}></div>
          </div>
          <div class="absolute h-full" style={"width:#{@bw}px;"}>
            <svg :if={@vy} class="absolute" viewBox="0 0 16 16" width={@bw} height={@bw} style={"bottom:#{@vy-@bw/2.0}px;"}>
              <polygon points="0,0 16,8 0,16" fill="currentColor" />
            </svg>
          </div>
        </div>
        """

      %{state: state} ->
        state
    end
  end
end
