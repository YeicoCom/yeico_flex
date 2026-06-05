defmodule Flex2.Buffer do
  use Flex2.Entity

  defp initial() do
    %{
      repo: nil
    }
  end

  defp checks() do
    %{
      repo: :binary
    }
  end

  defp start(%{repo: repo}, _) do
    setup(repo)
  end

  defp clean(_, _) do
    :nop
  end

  alias Applet.Api.Log
  alias Applet.Api.Bus
  alias Flex2.Utils
  alias Flex2.Repo

  def register(name) do
    pid = Utils.whereis(name)
    Process.monitor(pid)
    send(pid, {:state, self()})

    receive do
      {__MODULE__, :state, result} -> result
    after
      5_000 -> throw(timeout: :state)
    end
  end

  defp setup(repo) do
    Bus.subscribe!(:daemon, nil)

    {_pid, _root, files} = Repo.register(repo)

    for {path, _} <- files do
      {path, []}
    end
    |> Enum.into(%{})
    |> loop()
  end

  defp loop(files) do
    receive do
      {Repo, path, nil} ->
        files = Map.delete(files, path)
        loop(files)

      {Repo, path, _} ->
        files = Map.put_new(files, path, [])
        loop(files)

      # not missing new files logs depends on enough
      # time between file creation and its enablement
      # it is in our favor that files are created disabled
      # this is clearly not fully correct but looks safe enough
      {:daemon, _, {path, level, msg}} ->
        id = Utils.id()
        stamp = NaiveDateTime.utc_now()
        Bus.broadcast!(:buffer, {id, stamp, path, level, msg})

        files =
          case files[path] do
            nil ->
              files

            list ->
              log = %{id: id, stamp: stamp, level: level, msg: msg}
              list = [log | list]
              list = Enum.take(list, 25)
              Map.put(files, path, list)
          end

        loop(files)

      {:state, caller} ->
        send(caller, {__MODULE__, :state, files})
        loop(files)

      # repo monitored on registration
      {:DOWN, _ref, :process, _pid, _reason} ->
        loop(files)

      unexpected ->
        Log.warn(module: __MODULE__, unexpected: unexpected)
        loop(files)
    end
  end
end
