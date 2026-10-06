defmodule Flex.ElixirScript do
  use Flex.Entity

  defp initial() do
    %{
      code: nil
    }
  end

  defp checks() do
    %{
      code: :binary
    }
  end

  defp start(%{code: code}, _) do
    Process.flag(:trap_exit, true)
    Process.put(:mod?, true)
    evals(code)
  end

  defp clean(_, _) do
    :nop
  end

  defp evals(code) do
    {result, diagnostics} =
      Code.with_diagnostics(fn ->
        try do
          Code.eval_string(code, [], file: "script.exs")
          :ok
        rescue
          error -> [rescue: error, stack: __STACKTRACE__]
        catch
          error -> [catch: error, stack: __STACKTRACE__]
        end
      end)

    # position is row or {row, col}
    Enum.each(diagnostics, fn
      %{severity: :warning, position: p, message: m} ->
        Log.warn("pos:#{inspect(p)} compile warning #{m}")

      %{severity: :error, position: p, message: m} ->
        Log.error("pos:#{inspect(p)} compile error #{m}")
    end)

    # default is flush blocking, scripts are not cron tasks
    case result do
      :ok -> Utils.flush()
      _ -> Log.error(result)
    end
  end
end
