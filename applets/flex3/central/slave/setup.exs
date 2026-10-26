use Terminal

Api.evalf("setup/view.exs", path: "/", props: %{theme: "dark"})

Api.evalf("setup/browser.exs", url: "https://127.0.0.1", monitor: 0)

:ok
