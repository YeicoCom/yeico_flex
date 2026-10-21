use Terminal.Live

# http://localhost:4080/hmi1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "HMI")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(theme: "light")
|> Flex.LiveScreen.set(shared: %{menu: 0})
|> Flex.LiveScreen.add(
  {0, 0},
  Flex.ReactorWrapper,
  inputs: [
    {:tzoffset, {:shared, :tzoffset}},
    {:menu, {:shared, :menu}},
    {:time, {:timer, 1000}}
  ],
  handler: fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="bg-base-200 w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center gap-[4px]">
          <div>Screen Title</div>
          <div class="grow"/>
          <div class="hero-wifi"/>
          <div class="hero-arrows-up-down"/>
        </div>
      </div>
      <div class="h-[400px]"/>
      <div class="bg-base-200 w-[800px] h-[40px] px-[6px] flex flex-cols items-center">
        <div class="w-full text-[20px] flex items-center">
          <img src="/applets/logo.svg" class="h-[28px] pe-4 grayscale">
          <div :for={menu <- 0..2} class={["px-3 py-2 cursor-pointer rounded", @inputs.menu==menu && "bg-neutral text-neutral-content"]}
            phx-click="click:menu" phx-value-index={@index} phx-value-menu={menu}>{"Menu#{menu}"}</div>
          <div class="grow"/>
          <div>{@state.time}</div>
        </div>
      </div>
      """

    %{state: state, event: {:event, "click:menu", %{"menu" => menu}}, share: share} ->
      share.(:menu, String.to_integer(menu))
      state

    %{state: state, inputs: %{tzoffset: tzoffset}} ->
      time =
        NaiveDateTime.utc_now()
        |> NaiveDateTime.shift(hour: tzoffset || 0)
        |> Calendar.strftime("%H:%M:%S")

      Map.put(state, :time, time)
  end
)
|> Flex.LiveScreen.add({100, 100}, Flex.MovingAnalogIndicator,
  visible: {:shared, :menu},
  visible?: fn menu -> menu == 0 end
)
|> Flex.LiveScreen.run()

:ok
