use Terminal

Api.evalf("setup/view.exs", path: "/", props: %{theme: "dark"})

Api.evalf("setup/browser.exs")
Flex.Browser.start("https://127.0.0.1", 0)

:ok
