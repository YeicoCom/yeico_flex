defmodule Wire.Loop do
  use Terminal

  defp sudo?(cmd) do
    case Terminal.user() do
      "root" -> cmd
      _ -> "sudo #{cmd}"
    end
  end

  defp shell(cmd, trace \\ false) do
    cmd = sudo?(cmd)
    # wg-quick code 127 missing resolvconf
    path = "/usr/sbin:#{System.get_env("PATH")}"
    {output, code} = System.shell(cmd, env: [{"PATH", path}], stderr_to_stdout: true)
    lines = String.split(output, "\n", trim: true)
    Log.debug(cmd: cmd, code: code)
    for line <- lines, do: if(trace, do: Log.trace(line))
    %{cmd: cmd, code: code, output: output, lines: lines}
  end

  defp loop(nets, error) do
    # single change triggers full restart since a change
    # in one net may triggers errors on another
    # Api.receive()
    receive do
      {"wire:reload", _, {net, suffix, peer}} ->
        nic = String.downcase(net)
        Log.debug("wire:reload #{nic}:#{suffix}:#{peer}")
        path = Terminal.fpath("@home/wire.d/#{nic}.conf")
        enabled = File.exists?(path)
        if enabled, do: shell("wg set #{nic} peer '#{peer}' remove ")
        if enabled, do: shell("wg syncconf #{nic} #{path}.strip")
        loop(nets, error)

      unexpected ->
        unexpected
    after
      1_000 ->
        status =
          for {_, net} <- nets, reduce: %{} do
            status ->
              nic = String.downcase(net.name)
              %{code: code, output: output} = shell("wg show #{nic} dump")
              lines = if(code == 0, do: String.split(output, "\n"), else: [])
              now = System.system_time(:second)

              for line <- lines, reduce: status do
                status ->
                  case String.split(line) do
                    [pub, _, "(none)", _, _, _, _, _] ->
                      Map.delete(status, pub)

                    [pub, _, _, _, hs, _, _, _] ->
                      hs = String.to_integer(hs)
                      Map.put(status, pub, stamp(now - hs))

                    _ ->
                      status
                  end
              end
          end

        Api.putcast!("wire:status", status)
        loop(nets, error)
    end
  end

  def setup(_opts) do
    Bus.subscribe!("wire:save", nil)
    Bus.subscribe!("wire:reload", nil)
    Api.putcast!("wire:status", %{})

    shell("echo 1 > /proc/sys/net/ipv4/ip_forward")

    for path <- Terminal.fpath("@home/wire.d/*.conf") |> Path.wildcard() do
      shell("wg-quick down #{path}")
      shell("rm -f #{path}.strip")
      shell("rm -f #{path}")
    end

    nets = Wire.Store.list()
    error = Wire.Valid.check(nets)
    Api.putcast!("wire:error", error)
    nets = Enum.filter(nets, fn {_, net} -> net.status == "Enabled" end)
    nets = nets |> Enum.filter(fn {nid, _} -> !error[nid][:error?] end)

    error =
      for {nid, net} <- nets, reduce: error do
        error ->
          nic = String.downcase(net.name)
          path = Terminal.fpath("@home/wire.d/#{nic}.conf")
          conf = Wire.Template.master(net)
          File.write!(path, conf)
          File.chmod(path, 0o770)
          shell("wg-quick strip #{path} > #{path}.strip")
          %{code: code, output: output} = shell("wg-quick up #{path}")
          error? = if(code == 0, do: false, else: :failed)
          error |> put_in([nid, :error?], error?) |> put_in([nid, :error], output)
      end

    Api.putcast!("wire:error", error)

    nets = nets |> Enum.filter(fn {nid, _} -> !error[nid][:error?] end)
    loop(nets, error)
  end

  defp stamp(seconds) do
    days = Integer.floor_div(seconds, 24 * 60 * 60)
    seconds = rem(seconds, 24 * 60 * 60)
    hours = Integer.floor_div(seconds, 60 * 60)
    seconds = rem(seconds, 60 * 60)
    minutes = Integer.floor_div(seconds, 60)
    seconds = rem(seconds, 60)

    "#{days}d#{hours}h#{minutes}m#{seconds}s"
    |> String.trim_leading("0")
    |> String.trim_leading("d")
    |> String.trim_leading("0")
    |> String.trim_leading("h")
    |> String.trim_leading("0")
    |> String.trim_leading("m")
  end
end
