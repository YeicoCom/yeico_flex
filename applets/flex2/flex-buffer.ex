defmodule Flex2.Buffer do
  alias Applet.Api.Log
  alias Applet.Api.Bus
  alias Flex2.Async
  alias Flex2.Utils
  alias Flex2.Repo

  def start() do
    stamp = Utils.stamp()
    name = Utils.inspect?(__MODULE__)
    Async.spawn("#{stamp}:#{name}", &setup/0)
  end

  def state() do
    pid = Utils.pid(__MODULE__)
    send(pid, {:state, self()})

    receive do
      {:state, result} -> result
    after
      5_000 -> throw(timeout: :state)
    end
  end

  defp setup() do
    # subscribe before register for daemon to wait on it
    Bus.subscribe!(:daemon, nil)
    Process.register(self(), __MODULE__)
    Process.flag(:trap_exit, true)

    # fixme: need to track repos death
    {_root, files} = Repo.register()

    for {path, _} <- files do
      {path, []}
    end
    |> Enum.into(%{})
    |> loop()
  end

  defp loop(files) do
    receive do
      {Repo, _, {path, nil}} ->
        files = Map.delete(files, path)
        loop(files)

      {Repo, _, {path, _}} ->
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
        send(caller, {:state, files})
        loop(files)

      unexpected ->
        Log.warn(unexpected: unexpected)
        loop(files)
    end
  end
end
