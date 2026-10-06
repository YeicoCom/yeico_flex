use Terminal

Flex.ElixirScript.new()
|> Flex.ElixirScript.set(code: "")
|> Flex.ElixirScript.run(rdms: 2_000)

Flex.ReactiveLogic.new()
|> Flex.ReactiveLogic.set(map: "adb")
|> Flex.ReactiveLogic.add(
  fn ctx = %{inputs: %{c: c}} ->
    if rem(c, 3) == 2, do: ctx.put.("dev:point", c)
    # if rem(c, 5) == 3, do: throw("hi")
    Map.put(ctx.state, :c, c)
  end,
  a: {:const, 0},
  b: {:point, "dev:point"},
  c: {:timer, 1000}
)
|> Flex.ReactiveLogic.run(deps: ["adb"])

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(map: "adb")
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "LS1")
|> Flex.LiveScreen.set(style: "background-color: gray;")
|> Flex.LiveScreen.set(width: 80, height: 60)
|> Flex.LiveScreen.add(
  [2, 1],
  fn
    ctx = %{event: :render, assigns: assigns} ->
      # ctx.debug.(event: ctx.event, inputs: ctx.inputs, state: ctx.state)
      use Flex.Live

      # if rem(c, 3) == 1, do: throw("hi")
      assigns = Map.put(assigns, :b, ctx.state.b)
      assigns = Map.put(assigns, :c, ctx.state.c)

      ~H"""
      <div phx-click="timer" phx-value-index={@index}>Timer {@c}</div>
      <div phx-click="point" phx-value-index={@index}>Point {@b}</div>
      <style>
      @scope { div {background-color: green; }}
      </style>
      """

    ctx = %{inputs: %{c: c, b: b}} ->
      # if rem(c, 3) == 2, do: throw("hi")
      # ctx.debug.(event: ctx.event, inputs: ctx.inputs, state: ctx.state)
      Map.merge(ctx.state, %{c: c, b: b})
  end,
  a: {:const, 0},
  b: {:point, "dev:point"},
  c: {:timer, 1000}
)
|> Flex.LiveScreen.run(deps: ["adb"])

:ok
