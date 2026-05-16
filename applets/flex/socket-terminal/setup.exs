use Flex

Flex.eval_file("iutils.exs", [])
Flex.eval_file("index.exs", [])
Flex.run_view("index.exs", Flex.SocketTerminal.Index, [])

:ok
