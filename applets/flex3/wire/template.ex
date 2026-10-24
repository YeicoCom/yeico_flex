defmodule Wire.Template do
  use Terminal

  @master """
  #<%= net.nic %>
  [Interface]
  PrivateKey = <%= net.priv %>
  Address = <%= net.ipmask %>
  ListenPort = <%= net.port %>
  <%= if linux? do %>
  PreUp = echo 1 > /proc/sys/net/ipv4/ip_forward
  PreUp = iptables -A FORWARD -o <%= net.nic %> -j ACCEPT
  PostDown = iptables -D FORWARD -o <%= net.nic %> -j ACCEPT
  #PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
  <% end %>
  <%= for {_, node} <- net.nodes do %>
  #<%= node.name %>
  [Peer]
  PublicKey = <%= node.pub %>
  AllowedIPs = <%= [node.address | node.exports] |> Enum.join(", ") %>
  PersistentKeepalive = 20
  <% end %>
  """

  @node """
  #<%= node.name %>@<%= net.nic %>
  [Interface]
  Address = <%= node.ipmask %>
  PrivateKey = <%= node.priv %>
  <%= if length(node.exports) > 0 do %>
  PreUp = echo 1 > /proc/sys/net/ipv4/ip_forward
  PreUp = iptables -A FORWARD -o <%= net.nic %> -j ACCEPT
  PreUp = iptables -A FORWARD -i <%= net.nic %> -j ACCEPT
  PostDown = iptables -D FORWARD -o <%= net.nic %> -j ACCEPT
  PostDown = iptables -D FORWARD -i <%= net.nic %> -j ACCEPT
  # PostDown = echo 0 > /proc/sys/net/ipv4/ip_forward
  <% end %>
  <%= for %{nic: nic} <- node.exported do %>
  PreUp = iptables -t nat -A POSTROUTING -o <%= nic %> -j MASQUERADE
  PostDown = iptables -t nat -D POSTROUTING -o <%= nic %> -j MASQUERADE
  <% end %>
  [Peer]
  PublicKey = <%= net.pub %>
  AllowedIPs = <%= [net.netmask | node.imports] |> Enum.join(", ") %>
  Endpoint = <%= fqhn %>:<%= net.port %>
  PersistentKeepalive = 20
  """

  @yaml """
  #<%= node.name %>@<%= net.nic %>
  Address: <%= node.ipmask %>
  PrivateKey: <%= node.priv %>
  PublicKey: <%= net.pub %>
  AllowedIPs: <%= [net.netmask | node.imports] |> Enum.join(", ") %>
  Endpoint: <%= fqhn %>:<%= net.port %>
  PersistentKeepalive: 20
  Masquerade: [<%= node.nats %>]
  """

  @hosts """
  <%= for {_, node} <- net.nodes do %>
  <%= node.ip %>\t<%= node.host %>.<%= net.nic %>
  <% end %>
  """

  def master(net) do
    net = calculate(net)
    eval(@master, net: net)
  end

  def node(net, index) do
    net = calculate(net)
    node = net.nodes[index]
    eval(@node, net: net, node: node)
  end

  def yaml(net, index) do
    net = calculate(net)
    node = net.nodes[index]
    eval(@yaml, net: net, node: node)
  end

  def hosts(net) do
    net = calculate(net)
    eval(@hosts, net: net)
  end

  defp calculate(net = %{name: name, prefix: prefix, nodes: nodes}) do
    dots = String.count(prefix, ".")

    nodes = Enum.filter(nodes, fn {_, n} -> n.status == "Enabled" end)

    nodes =
      for {index, node} <- nodes, into: %{} do
        {index, calculate(node, prefix)}
      end

    ipmask =
      case dots do
        0 -> "#{prefix}.0.0.254/8"
        1 -> "#{prefix}.0.254/16"
        2 -> "#{prefix}.254/24"
      end

    netmask =
      case dots do
        0 -> "#{prefix}.0.0.0/8"
        1 -> "#{prefix}.0.0/16"
        2 -> "#{prefix}.0/24"
      end

    net
    |> Map.put(:nodes, nodes)
    |> Map.put(:ipmask, ipmask)
    |> Map.put(:netmask, netmask)
    |> Map.put(:nic, String.downcase(name))
  end

  defp calculate(node = %{name: name, suffix: suffix, exports: exports, imports: imports}, prefix) do
    dots = String.count(prefix, ".")

    ipmask =
      case dots do
        0 -> "#{prefix}.#{suffix}/8"
        1 -> "#{prefix}.#{suffix}/16"
        2 -> "#{prefix}.#{suffix}/24"
      end

    exported =
      exports
      |> String.split(",", trim: true)
      |> Enum.map(&String.split(&1, ":"))
      |> Enum.map(fn [nic, cidr] -> %{nic: nic, cidr: cidr} end)

    imports =
      imports
      |> String.split(",", trim: true)

    ip = "#{prefix}.#{suffix}"
    address = "#{prefix}.#{suffix}/32"
    exports = Enum.map(exported, & &1.cidr)
    nats = exported |> Enum.map(& &1.nic) |> Enum.join(", ")

    node
    |> Map.put(:ip, ip)
    |> Map.put(:ipmask, ipmask)
    |> Map.put(:exported, exported)
    |> Map.put(:exports, exports)
    |> Map.put(:imports, imports)
    |> Map.put(:address, address)
    |> Map.put(:nats, nats)
    |> Map.put(:host, String.downcase(name))
  end

  defp globals() do
    [
      linux?: match?({:unix, :linux}, :os.type()),
      fqhn: Api.hostname_f()
    ]
  end

  defp eval(template, opts) do
    opts = opts ++ globals()

    EEx.eval_string(template, opts)
    |> String.split("\n", trim: true)
    |> Enum.join("\n")
  end
end
