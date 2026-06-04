defmodule Flex.ModbusSlave.Loop do
  use Flex.Use

  defp handle({conn = %{socket: socket}, params = %{apply: apply}}) do
    receive do
      {:tcp, ^socket, data} ->
        :ok = Tcp.write(conn, apply.(data))
        handle({conn, params})

      unexpected ->
        Log.debug(unexpected: unexpected)
    end
  end

  defp accept(socket, params) do
    {:ok, conn} = Tcp.accept(socket)
    cid = "#{conn.peer.ip}:#{conn.peer.port}"
    Log.info("Modbus slave client: #{cid}")
    task = Api.async(&handle/1, {conn, params}, tag: "slave:client:#{cid}")
    Tcp.owner(conn, task)
    accept(socket, params)
  end

  def setup opts do
    port = Keyword.fetch!(opts, :port)
    proto = Keyword.fetch!(opts, :proto) |> Modbus.get_proto()
    apply = fn data -> Modbus.slave_apply(proto, "flex:modbus-slave:model", data) end
    {:ok, socket} = Tcp.listen("127.0.0.1", port, active: true)
    Log.info("Modbus slave #{proto.id()} port: #{socket.port}")
    accept(socket, %{apply: apply})
  end
end
