defmodule Flex.UserFiles.IUtils do
  use Flex

  @name "User File"
  @status [:disabled, :enabled]
  @options %{status: @status}
  @new %{name: @name, status: :enabled}

  def merge(item), do: Map.merge(@new, item)

  def style(:error), do: "text-red-500"
  def style(:warn), do: "text-yellow-500"
  def style(:info), do: "text-blue-500"
  def style(:debug), do: "text-teal-500"
  def style(:trace), do: "text-gray-500"
  def style(:unhandled), do: "text-red-700"

  def modal(args) do
    case args do
      {:edit, state, id, item} ->
        Map.put(state, :modal, %{
          title: "Edit #{@name}",
          item: item,
          id: id,
          opts: @options
        })

      {:add, state} ->
        Map.put(state, :modal, %{
          title: "Add #{@name}",
          item: @new,
          id: nil,
          opts: @options
        })
    end
  end

  def index(pairs), do: Enum.map(pairs, fn {k, _} -> k end)

  def apply(item, "enable"), do: Map.put(item, :status, :enabled)
  def apply(item, "disable"), do: Map.put(item, :status, :disabled)

  def parse(params) do
    params = Map.update!(params, "name", &(String.replace(&1, ~r/ +/, " ") |> String.trim()))
    params = Map.update!(params, "status", &String.to_atom/1)
    params = Enum.map(params, fn {k, v} -> {String.to_atom(k), v} end)
    Enum.into(params, %{})
  end

  def append(udir, id, name, _pos, nil) do
    ext = Path.extname(name)
    dt = System.os_time(:millisecond)
    path1 = Path.join(udir, "#{id}.tmp")
    path2 = Path.join(udir, "#{id}.#{dt}#{ext}")
    path3 = Path.join(udir, id)
    :ok = File.rename(path1, path2)
    {:ok, _} = File.rm_rf(path3)
    :ok = File.ln_s(Path.basename(path2), path3)
    Bus.broadcast!("flex:user-files:reload:#{id}", nil)
  end

  def append(udir, id, _name, pos, data) do
    path = Path.join(udir, "#{id}.tmp")
    mode = if pos > 0, do: [:append], else: [:write]
    {:ok, file} = File.open(path, mode)
    :ok = IO.binwrite(file, Base.decode64!(data))
    :ok = File.close(file)
  end

  def find(id) do
    with path <- Api.path("static/upload/#{id}"),
         {:ok, link} <- File.read_link(path) do
      link
    else
      _ -> nil
    end
  end
end

:ok
