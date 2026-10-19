defmodule Flex.Vapid do
  use Terminal.Live

  def load_config(path) do
    Api.path(path) |> File.read!() |> Jason.decode!()
  end

  def build_vars(vapid_config) do
    [
      {"VAPID_PUBKEY", vapid_config["publicKey"]},
      {"VAPID_PRIVKEY", vapid_config["privateKey"]}
    ]
  end

  def get_pusher(node, prefix) do
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
