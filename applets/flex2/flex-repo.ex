defmodule Flex2.Repo do
  alias Applet.Api.Log
  alias Applet.Api.Bus
  alias Flex2.Setter
  alias Flex2.Async
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

  def add(root, type), do: create(root, type)
  def del(repo, path), do: join(repo, path) |> File.rm()
  def save(repo, path, data), do: join(repo, path) |> File.write(data)
  def stop(repo, path), do: join(repo, path) |> File.chmod(0o666)
  def start(repo, path), do: join(repo, path) |> File.chmod(0o777)

  def start(path) do
    Setter.check(:path, path, {:starts_with?, "/"})
    paths = for sub <- @subs, do: Path.join(path, sub)
    for path <- paths, do: Terminal.dpath(path)
    stamp = Utils.stamp()
    name = Utils.inspect?(__MODULE__)
    Async.spawn("#{stamp}:#{name}", &setup/1, path)
  end

  def register() do
    pid = Utils.pid(__MODULE__)
    # cascade kill without pid tracking
    # here because it excepts when pid is not alive
    Process.link(pid)
    Bus.subscribe!(__MODULE__, nil)
    send(pid, {:register, self()})

    receive do
      {__MODULE__, :register, path, files} -> {path, files}
    after
      5_000 -> throw(timeout: {:register, self()})
    end
  end

  defp setup(path) do
    Process.register(self(), __MODULE__)
    Process.flag(:trap_exit, true)
    paths = for sub <- @subs, do: Path.join(path, sub)
    # macos has a 0.5s default latency
    {:ok, pid} = FileSystem.start_link(dirs: paths, latency: 0)
    FileSystem.subscribe(pid)
    # fixme: file monitoring ready at this point?
    loop(path, load(path, @subs))
  end

  defp loop(root, files) do
    receive do
      {:register, pid} ->
        send(pid, {__MODULE__, :register, root, files})
        loop(root, files)

      {:file_event, _pid, {path, _events}} ->
        files = update(files, root, path)
        loop(root, files)

      {:EXIT, _pid, _reason} ->
        loop(root, files)

      unexpected ->
        Log.warn(unexpected: unexpected)
        loop(root, files)
    end
  end

  defp update(files, root, path) do
    relative = Path.relative_to(path, root)

    case load(path) do
      nil ->
        broadcast(relative, files[relative], nil)
        Map.delete(files, relative)

      payload ->
        broadcast(relative, files[relative], payload)
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

  defp join(root, path) do
    true = File.dir?(root)
    [type, name] = String.split(path, "/")
    true = Path.join(root, type) |> File.dir?()
    true = String.ends_with?(name, ".exs")
    true = type in @subs
    Path.join(root, path)
  end

  # fixme: bus broadcasting has out of sync potential
  defp broadcast(_relative, same, same), do: :nop
  defp broadcast(relative, _prev, next), do: Bus.broadcast!(__MODULE__, {relative, next})

  defp template("script"), do: @script
  defp template("backend"), do: @backend
end
