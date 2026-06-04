defmodule Flex2.ShellCommand do
  use Flex2.Entity

  defp initial() do
    %{
      run: nil,
      kill: nil
    }
  end

  defp checks() do
    %{
      run: :binary,
      kill: :binary?
    }
  end

  defp start(%{run: run}) do
    System.shell(run, stderr_to_stdout: true)
  end

  defp clean(%{kill: kill}) do
    if kill, do: System.shell(kill)
  end
end
