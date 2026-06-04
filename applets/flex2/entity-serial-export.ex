defmodule Flex2.SerialExport do
  use Flex2.Entity

  defp initial() do
    %{
      tty: nil,
      bits: "8n1",
      bauds: 9600,
      ip: "127.0.0.1",
      port: 0
    }
  end

  defp checks() do
    %{
      tty: :binary,
      bits: {:in, ["8n1"]},
      bauds: {:in, [9600, 115_200]},
      port: {:integer, 0, 65_535},
      ip: {:in, ["127.0.0.1", "0.0.0.0"]}
    }
  end

  # pid on $! does not depend on sudo/socat success
  defp start(entity) do
    pidf = pid_file(entity)

    entity
    |> check_tty()
    |> socat_cmd()
    |> prepend_sudo()
    |> append(" &\necho $! > #{pidf}")
    |> System.shell(stderr_to_stdout: true)
  end

  defp clean(entity) do
    pidf = pid_file(entity)

    "kill -9 $(cat #{pidf})"
    |> prepend_sudo()
    |> prepend("[ -f #{pidf} ] && ")
    |> append("\nrm -f #{pidf}")
    |> System.shell(stderr_to_stdout: true)
  end

  defp socat_cmd(%{tty: tty, bauds: bauds, ip: ip, port: port}) do
    case :os.type() do
      {:unix, :linux} ->
        "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},b#{bauds},raw,echo=0"

      {:unix, :darwin} ->
        "socat TCP-LISTEN:#{port},bind=#{ip},reuseaddr #{tty},ispeed=#{bauds},ospeed=#{bauds},clocal=1,nonblock=1,raw,echo=0"
    end
  end

  defp pid_file(%{tty: tty}) do
    filename = String.replace(tty, "/", "_")
    Terminal.fpath("@tmp/serial-export/#{filename}.pid")
  end

  defp check_tty(entity = %{tty: tty}) do
    # otherwise tty device gets created by socat under sudo
    case File.lstat(tty) do
      {:ok, %File.Stat{type: :device}} ->
        entity

      # serial/by-id links are relative
      {:ok, %File.Stat{type: :symlink}} ->
        with {:ok, path} <- File.read_link(tty),
             dir <- Path.dirname(tty),
             path <- Path.expand(path, dir),
             {:ok, %File.Stat{type: :device}} <- File.lstat(path) do
          entity
        else
          result ->
            raise("Invalid #{tty}: #{inspect(result)}")
        end

      # socat wont open tty until connection
      # socat creates regulat file if tty if not found
      # tty may be removed while waiting for connection
      # risky because of the long reconnection delay
      # socat exits on socket disconnection allowing removed tty detection
      result = {:ok, %File.Stat{type: :regular}} ->
        cmd = prepend_sudo("rm -f #{tty}")
        System.shell(cmd, stderr_to_stdout: true)
        raise("Invalid #{tty}: #{inspect(result)}")

      result ->
        raise("Invalid #{tty}: #{inspect(result)}")
    end
  end

  defp prepend_sudo(cmdline) do
    # sudo creates two processes
    case Terminal.user() do
      "root" -> cmdline
      _ -> prepend(cmdline, "sudo ")
    end
  end

  defp prepend(cmd, prefix), do: "#{prefix}#{cmd}"
  defp append(cmd, suffix), do: "#{cmd}#{suffix}"
end
