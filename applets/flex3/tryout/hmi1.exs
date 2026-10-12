use Terminal.Live

# http://localhost:4080/hmi1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/hmi1")
|> Flex.LiveScreen.set(title: "HMI1")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(shared: %{menu: 0})
|> Flex.LiveScreen.add(
  {0, 0},
  [{:time, {:timer, 1000}}],
  fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="bg-neutral-300 w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center gap-[4px]">
          <div>Screen Title</div>
          <div class="grow"/>
          <div class="hero-wifi"/>
          <div class="hero-arrows-up-down"/>
        </div>
      </div>
      <div class="h-[400px]"/>
      <div class="bg-neutral-300 w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center">
          <img src="/applets/logo.svg" class="h-[28px] pe-4 grayscale">
          <div :for={menu <- 0..2} class={["px-3 py-1 cursor-pointer rounded", @shared.menu==menu && "bg-neutral-500 text-white"]}
            phx-click="click:menu" phx-value-index={@index} phx-value-menu={menu}>{"Menu#{menu}"}</div>
          <div class="grow"/>
          <div>{@state.time}</div>
        </div>
      </div>
      """

    %{state: state, event: {:event, "click:menu", %{"menu" => menu}}, share: share} ->
      share.(:menu, String.to_integer(menu))
      state

    %{state: state, global: %{tzoffset: tzoffset}} ->
      time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.shift(hour: tzoffset || 0)
        |> Calendar.strftime("%H:%M:%S")

      Map.put(state, :time, time)
  end
)
|> Flex.LiveScreen.reduce(Enum.with_index([5, 1.5, 7, nil, 0.5, 9, -1, 11]), fn config, {v, i} ->
  x = 60 + rem(i, 3) * 245
  y = 60 + div(i, 3) * 130
  # works!
  visible? = fn %{menu: menu} -> menu == 0 end

  config
  |> Flex.LiveScreen.add({x + 0, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {2.0, 6.0},
    error: {1.0, 8.0},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 30, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {nil, 6.0},
    error: {1.0, 8.0},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 60, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {2.0, 6.0},
    error: {nil, 8.0},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 90, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {nil, 6.0},
    error: {nil, 8.0},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 120, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {2.0, nil},
    error: {1.0, 8.0},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 150, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {2.0, 6.0},
    error: {1.0, nil},
    value: {:const, v}
  )
  |> Flex.LiveScreen.add({x + 180, y}, Flex.MovingAnalogIndicator,
    visible?: visible?,
    bar: {10, 100},
    range: {0.0, 10.0},
    warn: {2.0, nil},
    error: {1.0, nil},
    value: {:const, v}
  )
end)
|> Flex.LiveScreen.run()

:ok
