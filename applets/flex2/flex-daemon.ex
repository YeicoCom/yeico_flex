defmodule Flex2.Daemon do
  alias Applet.Api.Log
  alias Flex2.Runner
  alias Flex2.Async
  alias Flex2.Utils
  alias Flex2.Repo

  def start() do
    stamp = Utils.stamp()
    name = Utils.inspect?(__MODULE__)
    Async.spawn("#{stamp}:#{name}", &setup/0)
  end

  defp setup() do
    # ensure buffer is ready
    Utils.pid(Flex2.Buffer)
    Process.register(self(), __MODULE__)
    Process.flag(:trap_exit, true)
    # fixme: need to track repos death
    {_root, files} = Repo.register()

    for {path, {enabled, data}} <- files do
      {path, run(path, enabled, data)}
    end
    |> Enum.into(%{})
    |> loop()
  end

  defp loop(files) do
    receive do
      {Repo, path, nil} ->
        kill(files[path])
        files = Map.delete(files, path)
        loop(files)

      {Repo, path, {enabled, data}} ->
        kill(files[path])
        files = Map.put(files, path, run(path, enabled, data))
        loop(files)

      {:EXIT, _pid, _reason} ->
        loop(files)

      {:DOWN, _ref, :process, _pid, _reason} ->
        loop(files)

      unexpected ->
        Log.warn(unexpected: unexpected)
        loop(files)
    end
  end

  defp kill(nil), do: :nop
  defp kill(context), do: Runner.kill(context)

  defp run(_path, false, _data), do: nil

  defp run(path, true, data) do
    {module, _name} = modname(path)
    entity = %{code: data}
    Runner.run(module, entity, path, log: {:daemon, path})
  end

  defp modname("script/" <> name), do: {Flex2.ElixirScript, name}
  defp modname("backend/" <> name), do: {Flex2.ElixirBackend, name}
end
