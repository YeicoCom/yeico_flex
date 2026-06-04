use Terminal

Flex2.ElixirScript.new()
|> Flex2.ElixirScript.set(code: "")
|> Flex2.ElixirScript.run(rdms: 2_000)

Flex2.ReactiveLogic.new()
|> Flex2.ReactiveLogic.set(map: "adb")
|> Flex2.ReactiveLogic.add(
  fn ctx = %{inputs: %{c: c}} ->
    if rem(c, 3) == 2, do: ctx.put.("dev:point", c)
    # if rem(c, 5) == 3, do: throw("hi")
    Map.put(ctx.state, :c, c)
  end,
  a: {:const, 0},
  b: {:point, "dev:point"},
  c: {:timer, 1000}
)
|> Flex2.ReactiveLogic.run(rdms: 2_000, deps: ["adb"])

Flex2.LiveScreen.new()
|> Flex2.LiveScreen.set(map: "adb")
|> Flex2.LiveScreen.set(path: "/")
|> Flex2.LiveScreen.set(title: "LS1")
|> Flex2.LiveScreen.set(style: "background-color: gray;")
|> Flex2.LiveScreen.set(width: 80, height: 60)
|> Flex2.LiveScreen.add(
  [2, 1],
  fn
    ctx = %{event: :render, assigns: assigns} ->
      # ctx.debug.(event: ctx.event, inputs: ctx.inputs, state: ctx.state)
      use Flex2.Live

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
|> Flex2.LiveScreen.run(rdms: 2_000, deps: ["adb"])

:ok
