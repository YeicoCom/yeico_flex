use Terminal

Api.evalf("setup/browser.exs", url: "https://127.0.0.1", monitor: false, port: 0)
Api.evalf("setup/view.exs", path: "/", props: %{theme: "dark"})

:ok
