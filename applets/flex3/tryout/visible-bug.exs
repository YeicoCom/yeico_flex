use Terminal.Live

# failure mode: the view wont show, other services fail as well
# putting visible? definition inside the for comprehension fail
# 7 indicators iterated 0..5 fail
# 1 indicators iterated 0..50 fail
# moving visible? definition outside the comprehension makes it work
# removing the call to visible? within MovingAnalogIndicator makes it work

# works
visible? = fn %{menu: menu} -> menu == 0 end

# http://localhost:4080/visible-bug
Flex.LiveScreen.new()
|> Flex.LiveScreen.set(path: "/visible-bug")
|> Flex.LiveScreen.set(title: "Visible Bug")
|> Flex.LiveScreen.set(width: 800)
|> Flex.LiveScreen.set(height: 480)
|> Flex.LiveScreen.set(shared: %{menu: 0})
|> (fn config ->
      # works
      # visible? = fn %{menu: menu} -> menu == 0 end
      for {v, i} <- 0..50 |> Enum.with_index(), reduce: config do
        config ->
          # fails
          # visible? = fn %{menu: menu} -> menu == 0 end
          x = 10 + rem(i, 30) * 25
          y = 10 + div(i, 30) * 120

          config
          |> Flex.LiveScreen.add({x + 0, y}, Flex.MovingAnalogIndicator,
            # fails
            # visible? = fn %{menu: menu} -> menu == 0 end
            visible?: visible?,
            bar: {10, 100},
            range: {0.0, 10.0},
            warn: {2.0, 6.0},
            error: {1.0, 8.0},
            value: {:const, v}
          )
      end
    end).()
|> Flex.LiveScreen.run()

:ok
