defmodule Flex.Pt do
  use Flex

  def get_key(dir, type, name) do
    "#{dir}:#{type}:#{name}"
  end

  def get_tag(type, name) do
    "#{type}:#{name}"
  end

  # FIXME float is not covered by 0 default
  # default value here must cover all types below
  # keys must be typed to avoid type mixing
  def get_value(key) do
    case Adb.get("flex:point:#{key}") do
      nil -> get_def(key)
      val -> val
    end
  end

  def put_value(key, val) do
    Api.putcast!("flex:point:#{key}", val)
  end

  def subget_value(key) do
    case Api.subget!("flex:point:#{key}") do
      nil -> get_def(key)
      val -> val
    end
  end

  def get_sources do
    "flex:points:source"
    |> Mdb.lookup()
    |> Enum.map(fn {_, tag} -> tag end)
    |> Enum.sort()
  end

  def get_sinks do
    "flex:points:sink"
    |> Mdb.lookup()
    |> Enum.map(fn {_, tag} -> tag end)
    |> Enum.sort()
  end

  def get_screens do
    "flex:points:screen"
    |> Mdb.lookup()
    |> Enum.map(fn {_, tag} -> tag end)
    |> Enum.sort()
    |> Enum.map(fn tag ->
      [route, name] = String.split(tag, ":")
      {route, name}
    end)
  end

  def get_files do
    "flex:points:file"
    |> Mdb.lookup()
    |> Enum.map(fn {_, tag} -> tag end)
    |> Enum.sort()
    |> Enum.map(fn tag ->
      [id, name] = String.split(tag, ":")
      {id, name}
    end)
  end

  def get_limits(:uint16), do: %{step: 1, min: 0, max: 65_535}
  def get_limits(:sint16), do: %{step: 1, min: -32_768, max: 32_767}
  def get_limits(:float), do: %{step: "any", min: nil, max: nil}
  def get_limits(:bit), do: %{step: 1, min: 0, max: 1}

  defp get_def("source:float:" <> _), do: 0.0
  defp get_def("sink:float:" <> _), do: 0.0
  defp get_def("file:" <> _), do: nil
  defp get_def(_), do: 0
end

:ok
