defmodule Flex.Point do
  def get(key), do: Flex.Pt.get_value(key)
  def put(key, value), do: Flex.Pt.put_value(key, value)
  def subget(key), do: Flex.Pt.subget_value(key)
  def publish(type, tag), do: Flex.Pt.reg_point(type, tag)
  def list(type), do: Flex.Pt.list(type)
end
