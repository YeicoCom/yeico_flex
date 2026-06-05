defmodule Flex2.ShellCommand do
  use Flex2.Entity

  defp initial() do
    %{
      run: nil,
      kill: nil,
      e2o?: true,
      o2l?: false
    }
  end

  defp checks() do
    %{
      run: :binary,
      kill: :binary?,
      e2o?: :boolean,
      o2l?: :boolean
    }
  end

  defp start(%{run: run, e2o?: e2o?, o2l?: o2l?}, %{id: id}) do
    root = Entity.root(__MODULE__, id)
    exec(run, e2o?, o2l?, root)
  end

  defp clean(%{kill: kill, e2o?: e2o?, o2l?: o2l?}, %{id: id}) do
    root = Entity.root(__MODULE__, id)
    if kill, do: exec(kill, e2o?, o2l?, root)
    File.rm_rf(root)
  end

  defp exec(cmd, e2o?, o2l?, root) do
    opts = [stderr_to_stdout: e2o?, env: [{"FLEX2_RUN", root}], close_stdin: true]
    {out, es} = System.shell(cmd, opts)
    if o2l?, do: Log.trace(String.trim_trailing(out, "\n"))
    if o2l?, do: Log.trace(exit: es)
  end
end
