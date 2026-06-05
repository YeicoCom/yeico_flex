defmodule Flex2.Daemon do
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
  alias Flex2.Runner
  alias Flex2.Repo

  defp setup(repo) do
    # clean tasks, called directly on stop, are explicitly killed
    Process.flag(:trap_exit, true)

    {_pid, _root, files} = Repo.register(repo)

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

      # defer task result
      {ref, _res} when is_reference(ref) ->
        loop(files)

      unexpected ->
        Log.warn(module: __MODULE__, unexpected: unexpected)
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
