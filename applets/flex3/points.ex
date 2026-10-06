defmodule Flex3.Points do
  use Applet.Alias

  def get_key(dir, type, name) do
    "#{dir}:#{type}:#{name}"
  end

  def get_tag(type, name) do
    "#{type}:#{name}"
  end

  # default value here must cover all types below
  # keys must be typed to avoid type mixing
  def get_value(key) do
    case Adb.get("flex:point:#{key}") do
      nil -> get_def(key)
      val -> val
    end
  end

  def subget_value(key) do
    case Api.subget!("flex:point:#{key}") do
      nil -> get_def(key)
      val -> val
    end
  end

  def put_value(key, val) do
    check_value(key, val)
    Api.putcast!("flex:point:#{key}", val)
  end

  def reg_point(type, tag) do
    Mdb.register!("flex:points:#{type}", tag)
  end

  def get_sources do
    "source" |> list()
  end

  def get_sinks do
    "sink" |> list()
  end

  def get_screens do
    "screen"
    |> list()
    |> Enum.map(fn tag ->
      [route, name] = String.split(tag, ":")
      {route, name}
    end)
  end

  def get_files do
    "file"
    |> list()
    |> Enum.map(fn tag ->
      [id, name] = String.split(tag, ":")
      {id, name}
    end)
  end

  def parse(:bit, val), do: String.to_integer(val)
  def parse(:pulse, val), do: String.to_integer(val)
  def parse(:status, val), do: String.to_integer(val)
  def parse(:uint16, val), do: String.to_integer(val)
  def parse(:sint16, val), do: String.to_integer(val)
  def parse(:float, val), do: Float.parse(val) |> elem(0)
  def parse("bit:" <> _, val), do: parse(:bit, val)
  def parse("pulse:" <> _, val), do: parse(:pulse, val)
  def parse("status:" <> _, val), do: parse(:status, val)
  def parse("uint16:" <> _, val), do: parse(:uint16, val)
  def parse("sint16:" <> _, val), do: parse(:sint16, val)
  def parse("float:" <> _, val), do: parse(:float, val)

  def get_limits(:bit), do: %{step: 1, min: 0, max: 1}
  def get_limits(:pulse), do: %{step: 1, min: -32_768, max: 32_767}
  def get_limits(:status), do: %{step: 1, min: 0, max: 3}
  def get_limits(:uint16), do: %{step: 1, min: 0, max: 65_535}
  def get_limits(:sint16), do: %{step: 1, min: -32_768, max: 32_767}
  def get_limits(:float), do: %{step: "any", min: nil, max: nil}
  def get_limits("bit:" <> _), do: get_limits(:bit)
  def get_limits("pulse:" <> _), do: get_limits(:pulse)
  def get_limits("status:" <> _), do: get_limits(:status)
  def get_limits("uint16:" <> _), do: get_limits(:uint16)
  def get_limits("sint16:" <> _), do: get_limits(:sint16)
  def get_limits("float:" <> _), do: get_limits(:float)

  def list(type) do
    "flex:points:#{type}"
    |> Mdb.lookup()
    |> Enum.map(fn {_, tag} -> tag end)
    |> Enum.sort()
  end

  defp check_value("sink:bit:" <> _, val), do: check_limits(:bit, val, &is_integer/1)
  defp check_value("sink:uint16:" <> _, val), do: check_limits(:uint16, val, &is_integer/1)
  defp check_value("sink:sint16:" <> _, val), do: check_limits(:sint16, val, &is_integer/1)
  defp check_value("sink:float:" <> _, val), do: check_limits(:float, val, &is_float/1)
  defp check_value("sink:status:" <> _, val), do: check_limits(:status, val, &is_integer/1)
  defp check_value("source:bit:" <> _, val), do: check_limits(:bit, val, &is_integer/1)
  defp check_value("source:uint16:" <> _, val), do: check_limits(:uint16, val, &is_integer/1)
  defp check_value("source:sint16:" <> _, val), do: check_limits(:sint16, val, &is_integer/1)
  defp check_value("source:float:" <> _, val), do: check_limits(:float, val, &is_float/1)
  defp check_value("source:status:" <> _, val), do: check_limits(:status, val, &is_integer/1)
  defp check_value(_key, _val), do: :ok

  defp check_limits(type, val, type?) do
    if !type?.(val), do: raise("Invalid value type for #{type}")
    %{min: min, max: max} = get_limits(type)
    if min && val < min, do: raise("Invalid value range for #{type}")
    if max && val > max, do: raise("Invalid value range for #{type}")
  end

  defp get_def("source:float:" <> _), do: 0.0
  defp get_def("sink:float:" <> _), do: 0.0
  defp get_def("screen:" <> _), do: nil
  defp get_def("file:" <> _), do: nil
  defp get_def(_), do: 0
end
