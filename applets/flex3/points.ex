defmodule Flex.Points do
  use Applet.Alias

  def get_key(dir, type, name) do
    "#{dir}:#{type}:#{name}"
  end

  # default value here must cover all types below
  # keys must be typed to avoid type mixing
  def get_value(key) do
    case Adb.get(key) do
      nil -> get_def(key)
      val -> val
    end
  end

  def subget_value(key) do
    case Api.subget!(key) do
      nil -> get_def(key)
      val -> val
    end
  end

  def put_value(key, val) do
    check_value(key, val)
    Api.putcast!(key, val)
  end

  def get_limits(:bit), do: %{step: 1, min: 0, max: 1}
  def get_limits(:status), do: %{step: 1, min: 0, max: 3}
  def get_limits(:uint16), do: %{step: 1, min: 0, max: 65_535}
  def get_limits(:sint16), do: %{step: 1, min: -32_768, max: 32_767}
  def get_limits(:float), do: %{step: "any", min: nil, max: nil}

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
  defp get_def(_), do: 0
end
