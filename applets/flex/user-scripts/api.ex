defmodule Flex.Script.Point do
  def get(key), do: Flex.Points.get_value(key)
  def put(key, value), do: Flex.Points.put_value(key, value)
  def subget(key), do: Flex.Points.subget_value(key)
  def publish(type, tag), do: Flex.Points.reg_point(type, tag)
  def list(type), do: Flex.Points.list(type)
end

defmodule Flex.Script.Api do
  def sleep(ms \\ :infinity) do
    Process.sleep(ms)
  end
end

defmodule Flex.Script do
  defmacro __using__(_) do
    quote do
      use Terminal.Live
      alias Flex.Script.Api
      alias Flex.Script.Point
    end
  end
end
