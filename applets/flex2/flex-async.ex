defmodule Flex2.Async do
  def spawn(tag, fun) do
    Applet.Api.async(wrap(fun), tag: tag)
  end

  def spawn(tag, fun, arg) do
    Applet.Api.async(wrap(fun), arg, tag: tag)
  end

  def defer(fun) do
    Applet.Api.defer(wrap(fun))
  end

  def wrap(fun) when is_function(fun, 0) do
    ctx = ctx()

    fn ->
      ctx(ctx)
      fun.()
    end
  end

  def wrap(fun) when is_function(fun, 1) do
    ctx = ctx()

    fn arg ->
      ctx(ctx)
      fun.(arg)
    end
  end

  def tag(), do: Process.get(:__tag__)
  def tag(tag), do: Process.put(:__tag__, tag)

  def api(), do: Process.get(:__api__)
  def api(api), do: Process.put(:__api__, api)

  def ctx(), do: Process.get(:__ctx__)
  def ctx(ctx), do: Process.put(:__ctx__, ctx)
end
