# Terminal

## Auth

- terminal.view auth: %{check: fun/1, key: key}
- route.check_live_auth check({path, query, get_session(conn, key)})
  - nil -> continue
  - url -> redirect
- /del/ENCODED_TOKEN to delete from session
- /put/ENCODED_TOKEN to append to session
