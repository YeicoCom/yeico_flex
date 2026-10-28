use Terminal.Live

Flex.Gauth.db_init()
Flex.Gauth.db_put("samuel.ventura@yeico.com")

Api.evalf("flex3/login.exs", props: %{})

Flex.LiveScreen.new()
|> Flex.LiveScreen.set(auth: Flex.Gauth.get_spec(:db))
|> Flex.LiveScreen.set(path: "/")
|> Flex.LiveScreen.set(title: "Gauth")
|> Flex.LiveScreen.set(barco: "gray")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add(
  {0, 0},
  Flex.ReactorWrapper,
  handler: fn
    assigns = %{event: :render} ->
      ~H"""
      <div class="p-2" hook="Gauth">
        <a href={Flex.Gauth.logout_url("/")}>Logout</a>
      </div>
      """

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
