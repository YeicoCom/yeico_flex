defmodule Flex2.Repo do
  use Flex2.Entity

  defp initial() do
    %{
      root: nil
    }
  end

  defp checks() do
    %{
      root: {:starts_with?, "/"}
    }
  end

  defp start(%{root: root}, _) do
    setup(root)
  end

  defp clean(_, _) do
    :nop
  end

  alias Applet.Api.Log
  alias Flex2.Setter
  alias Flex2.Utils

  @subs ["script", "backend"]

  @script """
  use Flex2.Script
  """

  @backend """
  use Flex2.Backend

  Log.debug(master: Environ.master())
  Log.debug(home: Environ.home())

  Mix.install([{:jason, "1.4.4"}], system_env: %{ID: __ENV__.file})
  Log.info(file: __ENV__.file)

  Utils.sleep()
  """

  # cd ~/.terminal/dev/flex2/repo/script
  # chmod +x script1.exs
  # chmod -x script1.exs
  def fs(:rename, root, path, new), do: rename(root, path, new)
  def fs(:save, root, path, data), do: join(root, path) |> File.write(data)
  def fs(:enable, root, path), do: join(root, path) |> File.chmod(0o777)
  def fs(:disable, root, path), do: join(root, path) |> File.chmod(0o666)
  def fs(:add, root, type), do: create(root, type)
  def fs(:rm, root, path), do: join(root, path) |> File.rm()

  def register(name) do
    pid = Utils.whereis(name)
    Process.monitor(pid)
    send(pid, {:register, self()})

    receive do
      {__MODULE__, :register, path, files} -> {pid, path, files}
    after
      5_000 -> throw(timeout: {:register, self()})
    end
  end

  defp setup(root) do
    paths = for sub <- @subs, do: Path.join(root, sub)
    for path <- paths, do: Utils.dpath(path)

    # macos has a 0.5s default latency
    {:ok, pid} = FileSystem.start_link(dirs: paths, latency: 0)
    FileSystem.subscribe(pid)
    # fixme: file monitoring ready at this point?
    loop(root, load(root, @subs), %{})
  end

  defp loop(root, files, pids) do
    receive do
      {:register, caller} ->
        ref = Process.monitor(caller)
        send(caller, {__MODULE__, :register, root, files})
        pids = Map.put(pids, caller, ref)
        loop(root, files, pids)

      {:file_event, _pid, {path, _events}} ->
        files = update(files, root, path, pids)
        loop(root, files, pids)

      {:DOWN, _ref, :process, pid, _reason} ->
        pids = Map.delete(pids, pid)
        loop(root, files, pids)

      unexpected ->
        Log.warn(module: __MODULE__, unexpected: unexpected)
        loop(root, files, pids)
    end
  end

  defp update(files, root, path, pids) do
    relative = Path.relative_to(path, root)

    case load(path) do
      nil ->
        broadcast(relative, files[relative], nil, pids)
        Map.delete(files, relative)

      payload ->
        broadcast(relative, files[relative], payload, pids)
        Map.put(files, relative, payload)
    end
  end

  defp load(root, subs) when is_list(subs) do
    paths = for sub <- subs, do: load(root, sub)
    paths |> List.flatten() |> Enum.into(%{})
  end

  defp load(root, sub) when is_binary(sub) do
    wild = Path.join([root, sub, "*.exs"])

    for path <- Path.wildcard(wild), reduce: [] do
      list ->
        relative = Path.relative_to(path, root)

        case load(path) do
          nil -> list
          payload -> [{relative, payload} | list]
        end
    end
  end

  defp exec?(mode), do: Bitwise.band(mode, 0o111) != 0

  defp load(path) do
    with {:ok, %File.Stat{mode: mode}} <- File.stat(path),
         {:ok, data} <- File.read(path) do
      {exec?(mode), data}
    else
      _ -> nil
    end
  end

  defp create(root, type, i \\ 1) do
    true = type in @subs
    path = Path.join([root, type, "#{type}#{i}.exs"])

    case File.open(path, [:write, :exclusive]) do
      {:ok, file} ->
        :ok = IO.binwrite(file, template(type))
        :ok = File.close(file)
        {Path.relative_to(path, root), load(path)}

      _ ->
        create(root, type, i + 1)
    end
  end

  defp rename(root, path, new) do
    path = join(root, path)
    new = join(root, new)

    case File.rename(path, new) do
      :ok ->
        {Path.relative_to(new, root), load(new)}

      _ ->
        {nil, {nil, nil}}
    end
  end

  defp join(root, path) do
    true = File.dir?(root)
    [type, name] = String.split(path, "/")
    true = Path.join(root, type) |> File.dir?()
    true = String.ends_with?(name, ".exs")
    true = type in @subs
    Path.join(root, path)
  end

  # fixme: bus broadcasting has out of sync potential
  defp broadcast(_relative, same, same, _pids), do: :nop

  defp broadcast(relative, _prev, next, pids) do
    for {pid, _} <- pids, do: send(pid, {__MODULE__, relative, next})
  end

  defp template("script"), do: @script
  defp template("backend"), do: @backend
end
