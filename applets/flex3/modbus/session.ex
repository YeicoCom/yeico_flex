defmodule Modbus.Session do
  alias Modbus.Command
  alias Modbus.Master
  use Applet.Alias

  @toms 5000

  def open(opts) do
    case Master.open(opts) do
      {:ok, conn} -> {:ok, Api.run(fn -> setup(conn) end)}
      other -> other
    end
  end

  def exec(pid, cmd, opts \\ []) do
    case is_binary(cmd) do
      true ->
        case Command.safe_parse(cmd) do
          {:ok, %{cmd: cmd, get: get}} ->
            case call?(pid, {:exec, cmd, opts}) do
              {:ok, values} -> {:ok, get.(values)}
              other -> other
            end

          other ->
            other
        end

      _ ->
        call?(pid, {:exec, cmd, opts})
    end
  end

  def close(pid) do
    call?(pid, :close)
  end

  defp call?(pid, req) do
    case Process.alive?(pid) do
      true -> call(pid, req)
      _ -> {:error, "not alive"}
    end
  end

  defp call(pid, req) do
    cid = UUID.uuid1()
    send(pid, {self(), cid, req})

    receive do
      {:res, ^cid, res} -> res
    after
      @toms -> {:error, "timeout"}
    end
  end

  defp setup(conn) do
    Api.defer(fn -> Master.close(conn) end)
    loop(conn)
  end

  defp loop(conn) do
    receive do
      {caller, cid, {:exec, cmd, opts}} ->
        case Master.exec(conn, cmd, opts) do
          {:ok, conn} ->
            send(caller, {:res, cid, :ok})
            loop(conn)

          {:ok, conn, values} ->
            send(caller, {:res, cid, {:ok, values}})
            loop(conn)

          {:error, conn, error} ->
            send(caller, {:res, cid, {:error, error}})
            loop(conn)
        end

      {caller, cid, :close} ->
        res = Master.close(conn)
        send(caller, {:res, cid, res})
    end
  end
end
