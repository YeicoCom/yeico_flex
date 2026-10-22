defmodule Flex.ShellCommand do
  use Flex.Service
  use Terminal

  defp specs,
    do: %{
      id: %{initial: nil, check: :binary},
      run: %{initial: nil, check: :binary},
      kill: %{initial: nil, check: :binary?},
      e2o?: %{initial: true, check: :boolean},
      o2l?: %{initial: false, check: :boolean}
    }

  defp name(%{id: id}), do: "shell-command:#{id}"

  defp setup(config = %{run: run, kill: kill, e2o?: e2o?, o2l?: o2l?}) do
    sid = name(config)
    dir = Terminal.dpath("@tmp/shell-command")
    clean(fn -> if kill, do: exec(kill, e2o?, o2l?, dir, "#{sid} kill") end)
    exec(run, e2o?, o2l?, dir, "#{sid} run")
    Api.warn(:exited)
  end

  # System.shell waits for background processes with trailing &
  # next shell script lines get executed but System.shell wont return
  # test with: System.shell("sleep 10 &")
  # nohup is required to fully disown and detach
  defp exec(cmd, e2o?, o2l?, dir, header) do
    Log.debug(header)
    opts = [stderr_to_stdout: e2o?, env: [{"FLEX_RUN", dir}], close_stdin: true]
    {out, exit_code} = System.shell(cmd, opts)
    if o2l?, do: Log.trace(String.trim_trailing(out, "\n"))
    if o2l?, do: Log.trace(exit_code: exit_code)
  end
end
