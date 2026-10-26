defmodule Wire.Store do
  use Terminal

  @min "00000000-0000-0000-0000-000000000000"
  @max "ffffffff-ffff-ffff-ffff-ffffffffffff"

  @name :wire_cubdb

  @net %{name: "<no-name>", prefix: "<no-prefix>", port: 0, status: "Disabled", nodes: %{}}

  def init() do
    {:ok, _} = CubDB.start_link(data_dir: Terminal.dpath("@home/#{@name}"), name: @name)
  end

  def def(), do: {UUID.uuid1(), @net}

  def save(:net, nid, net) do
    prev = get(nid)
    priv = net[:priv] || prev[:priv] || genpriv()
    pub = net[:pub] || prev[:pub] || genpub(priv)
    net = Map.put(net, :priv, priv)
    net = Map.put(net, :pub, pub)

    nodes =
      for {index, node} <- net.nodes, into: %{} do
        index = if index == "", do: UUID.uuid1(), else: index
        priv = node[:priv] || prev.nodes[index][:priv] || genpriv()
        pub = node[:pub] || prev.nodes[index][:pub] || genpub(priv)
        node = Map.put(node, :priv, priv)
        node = Map.put(node, :pub, pub)
        {index, node}
      end

    net = Map.put(net, :nodes, nodes)
    :ok = CubDB.put(@name, {:net, nid}, net)
    Bus.broadcast!("wire:save", {nid, net})
    {nid, net}
  end

  def delete(:net, nid) do
    :ok = CubDB.delete(@name, {:net, nid})
    Bus.broadcast!("wire:save", {nid, nil})
  end

  def get(nid) do
    CubDB.get(@name, {:net, nid}, @net)
  end

  def list() do
    CubDB.select(@name,
      min_key: {:net, @min},
      max_key: {:net, @max}
    )
    |> Stream.map(fn {{:net, k}, v} -> {k, v} end)
    |> Enum.to_list()
    |> Enum.into(%{})
  end

  def regen(item) do
    priv = genpriv()
    pub = genpub(priv)

    item
    |> Map.put(:priv, priv)
    |> Map.put(:pub, pub)
  end

  defp genpriv() do
    {priv, 0} = System.shell("wg genkey")
    String.trim(priv)
  end

  defp genpub(priv) do
    {pub, 0} = System.shell("echo #{priv} | wg pubkey")
    String.trim(pub)
  end
end
