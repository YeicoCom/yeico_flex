defmodule App.Pulse do
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []}
    }
  end

  def start_link() do
    {:ok, Task.async(fn -> init() end).pid}
  end

  defp init() do
    # dynamic call to make the compiler happy

    System.get_env()
    |> Enum.sort()
    |> Enum.each(fn {k, v} -> apply(Flex.Backend.Log, :debug, ["#{k}=#{v}"]) end)

    # throw(:EXCEPTION)

    loop(0)
  end

  defp loop(n) do
    Process.sleep(1000)
    puts("Pulse #{n}")
    loop(n + 1)
  end

  defp puts(line) do
    now = NaiveDateTime.utc_now()
    line = "#{now} #{line}"
    IO.puts(line)
  end
end
