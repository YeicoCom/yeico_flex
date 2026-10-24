defmodule Wire.Valid do
  use Terminal

  @name ~r/^[a-zA-Z][a-zA-Z0-9]*$/
  @exports ~r/^([a-z][a-z0-9]*):(\d+).(\d+).(\d+).(\d+)\/(\d+)$/
  @imports ~r/^(\d+).(\d+).(\d+).(\d+)\/(\d+)$/

  defp partial?(partial, reverse \\ false) do
    parts = String.split(partial, ".")
    parts = if(reverse, do: Enum.reverse(parts), else: parts)

    valids =
      parts
      |> Enum.map(&Integer.parse/1)
      |> Enum.with_index()
      |> Enum.filter(fn
        {{v, ""}, 0} -> v in 1..254
        {{v, ""}, _} -> v in 0..254
        _ -> false
      end)

    case {Enum.count(parts), Enum.count(valids)} do
      {p, p} when p in 1..3 -> true
      _ -> false
    end
  end

  def regex(:name), do: @name
  def regex(:exports), do: @exports

  def prefix?(prefix) do
    partial?(prefix)
  end

  def suffix?(prefix, suffix) do
    partial?(prefix) and
      partial?(suffix, true) and
      String.count("#{prefix}.#{suffix}", ".") == 3
  end

  def free?(suffix) do
    case {String.count(suffix, "."), suffix} do
      {0, "254"} -> false
      {1, "0.254"} -> false
      {2, "0.0.254"} -> false
      _ -> true
    end
  end

  def name?(name) do
    String.length(name) <= 15 and Regex.match?(@name, name)
  end

  def exports?(""), do: true

  def exports?(exports) do
    exports
    |> String.split(",")
    |> Enum.map(&Regex.run(@exports, &1))
    |> Enum.map(fn
      [_, _, a, b, c, d, m] ->
        [a, b, c, d, m] = Enum.map([a, b, c, d, m], &String.to_integer/1)
        a in 1..254 and b in 0..254 and c in 0..254 and d in 0..254 and m in [8, 16, 24, 32]

      _ ->
        false
    end)
    |> Enum.all?()
  end

  def imports?(""), do: true

  def imports?(imports) do
    imports
    |> String.split(",")
    |> Enum.map(&Regex.run(@imports, &1))
    |> Enum.map(fn
      [_, a, b, c, d, m] ->
        [a, b, c, d, m] = Enum.map([a, b, c, d, m], &String.to_integer/1)
        a in 1..254 and b in 0..254 and c in 0..254 and d in 0..254 and m in [8, 16, 24, 32]

      _ ->
        false
    end)
    |> Enum.all?()
  end

  def check(nets) do
    nets = Enum.filter(nets, fn {_, net} -> net.status == "Enabled" end)

    names =
      for {_, net} <- nets, reduce: %{} do
        names ->
          downname = String.downcase(net.name)
          Map.update(names, downname, 1, fn c -> c + 1 end)
      end

    ports =
      for {_, net} <- nets, reduce: %{} do
        ports ->
          Map.update(ports, net.port, 1, fn c -> c + 1 end)
      end

    for {nid, net} <- nets, into: %{} do
      error = nil

      downname = String.downcase(net.name)
      error = if(prefix?(net.prefix), do: error, else: "Invalid prefix")
      error = if(names[downname] == 1, do: error, else: "Duplicated name")
      error = if(ports[net.port] == 1, do: error, else: "Duplicated port")
      error = if(name?(net.name), do: error, else: "Invalid name")

      nodes = Enum.filter(net.nodes, fn {_, node} -> node.status == "Enabled" end)

      names =
        for {_, node} <- nodes, reduce: %{} do
          names ->
            downname = String.downcase(node.name)
            Map.update(names, downname, 1, fn c -> c + 1 end)
        end

      suffixes =
        for {_, node} <- nodes, reduce: %{} do
          suffixes ->
            Map.update(suffixes, node.suffix, 1, fn c -> c + 1 end)
        end

      nodes =
        for {index, node} <- nodes, into: %{} do
          error = nil

          downname = String.downcase(node.name)
          error = if(exports?(node.exports), do: error, else: "Invalid exports")
          error = if(imports?(node.imports), do: error, else: "Invalid imports")
          error = if(free?(node.suffix), do: error, else: "Reserved suffix")
          error = if(suffix?(net.prefix, node.suffix), do: error, else: "Invalid suffix")
          error = if(names[downname] == 1, do: error, else: "Duplicated name")
          error = if(suffixes[node.suffix] == 1, do: error, else: "Duplicated suffix")
          error = if(name?(node.name), do: error, else: "Invalid name")

          {index, %{error?: error != nil, error: error}}
        end

      error? = error != nil || Enum.any?(nodes, fn {_, %{error?: error?}} -> error? end)
      error = if error?, do: error || "Invalid nodes"

      {nid, %{error?: error?, error: error, nodes: nodes}}
    end
  end
end
