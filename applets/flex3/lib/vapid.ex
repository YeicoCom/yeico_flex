defmodule Flex.Vapid do
  use Terminal.Live

  def build(opts \\ []) do
    prefix = Keyword.get(opts, :prefix) || "/applets/flex3"
    config = Keyword.get(opts, :config) || "secret/vapid.json"
    name = Keyword.get(opts, :name) || "vapid"
    config = load_config(config)
    vars = build_vars(config)
    pubkey = config["publicKey"]
    node = "#{name}@#{Api.hostname()}.local" |> String.to_atom()
    pusher = get_pusher(node, prefix)
    %{name: name, node: node, pusher: pusher, pubkey: pubkey, vars: vars}
  end

  defp load_config(path) do
    Api.path(path) |> File.read!() |> Jason.decode!()
  end

  defp build_vars(vapid_config) do
    [
      {"VAPID_PUBKEY", vapid_config["publicKey"]},
      {"VAPID_PRIVKEY", vapid_config["privateKey"]}
    ]
  end

  defp get_pusher(node, prefix) do
    fn
      {:all, title, icon} ->
        msg = %{title: title, options: %{icon: "#{prefix}/#{icon}.png"}}
        send({:vapid, node}, {:all, msg})

      {:one, sub, title, icon} ->
        msg = %{title: title, options: %{icon: "#{prefix}/#{icon}.png"}}
        send({:vapid, node}, {:one, sub, msg})

      # add, del
      message ->
        send({:vapid, node}, message)
    end
  end
end
