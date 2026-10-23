defmodule Flex.Mail do
  use Terminal.Live

  def build(opts \\ []) do
    name = Keyword.get(opts, :name) || "mail"
    mpass = Keyword.get(opts, :mpass) || Api.path("secret/mail.pass")
    mconf = Keyword.get(opts, :mconf) || Api.path("secret/mail.exs")
    node = "#{name}@#{Api.hostname()}.local" |> String.to_atom()
    env = [{"MAIL_PASS", File.read!(mpass)}, {"MAIL_CONF", mconf}]
    sender = get_sender(node)
    %{name: name, node: node, env: env, sender: sender}
  end

  defp get_sender(node) do
    fn mail -> send({:mail, node}, {:send, mail}) end
  end
end
