defmodule Flex.EchoServer.Loop do
  use Flex

  defp handle(conn = %{socket: socket}) do
    receive do
      {:tcp, ^socket, data} ->
        :ok = Tcp.write(conn, data)
        handle(conn)

      unexpected ->
        Log.warn(unexpected: unexpected)
    end
  end

  defp accept(socket) do
    {:ok, conn} = Tcp.accept(socket)
    Log.info("Echo server client: #{conn.peer.ip}:#{conn.peer.port}")
    task = Api.async(&handle/1, conn)
    Tcp.owner(conn, task)
    accept(socket)
  end

  def setup opts do
    port = Keyword.fetch!(opts, :port)
    {:ok, socket} = Tcp.listen("127.0.0.1", port, active: true)
    Log.info("Echo server port: #{socket.port}")
    accept(socket)
  end
end

:ok
