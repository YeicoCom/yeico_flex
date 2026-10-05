use Terminal

Adb.reset()

Api.evalf("flex3/code.exs")
Api.evalf("flex3/test/check.exs")

Flex3.EchoServer.new(ip: "127.0.0.1")
|> Flex3.EchoServer.set(port: 8990)
|> Flex3.EchoServer.run()

:ok
