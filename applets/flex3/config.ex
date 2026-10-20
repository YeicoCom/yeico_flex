defmodule Flex.Config do
  def initial(specs) do
    for {name, %{initial: value}} <- specs, into: %{} do
      {name, value}
    end
  end

  def merge(config, opts) do
    for {name, value} <- opts, reduce: config do
      config ->
        Map.put(config, name, value)
    end
  end

  def compile(mod, specs, config) do
    specs =
      for {name, value} <- config, reduce: specs do
        specs ->
          specs
          |> update_in([name], &(&1 || %{}))
          |> put_in([name, :initial], value)
          |> update_in([name, :check], & &1)
      end

    for {name, %{initial: value, check: check}} <- specs, reduce: %{} do
      config ->
        path = "#{Applet.Api.inspect?(mod)}.#{name}"
        if !check, do: Flex.Check.abort(path, value, "not found")
        Flex.Check.check(path, value, check)
        Map.put(config, name, value)
    end
  end
end
