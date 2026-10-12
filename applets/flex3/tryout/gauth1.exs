use Terminal.Live

# test: google auth
# http://localhost:4080/gauth1
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(auth: Flex.Gauth.spec_db())
|> Flex.LiveScreen.set(path: "/gauth1")
|> Flex.LiveScreen.set(title: "Gauth")
|> Flex.LiveScreen.set(barco: "red")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.add(
  {0, 0},
  fn
    %{state: assigns, event: :render} ->
      ~H"""
      <div class="p-2" hook="Gauth">
        <a href={Flex.Gauth.logout_url("/gauth1")}>Logout</a>
      </div>
      """

    %{state: state} ->
      state
  end
)
|> Flex.LiveScreen.run()

:ok
