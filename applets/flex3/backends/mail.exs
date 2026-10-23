use Flex.Backend

Mix.install([{:gen_smtp, "1.3.0"}, {:castore, "~> 1.0"}],
  system_env: %{ID: __ENV__.file}
)

Api.var("MAIL_CERTS", CAStore.file_path())

# sample secret/mail.exs
# [
#   relay: "smtp.yeico.com",
#   port: 465,
#   username: "root@yeico.com",
#   password: var.("MAIL_PASS"),
#   auth: :always,
#   ssl: true,
#   tls: :never,
#   retries: 3,
#   no_mx_lookups: true,
#   # fallback confirmed to work
#   # sockopts: [verify: :verify_none]
#   # verified confirmed to work
#   sockopts: [
#     # >=3 works
#     depth: 3,
#     cacertfile: var.("MAIL_CERTS")
#   ]
#   # uncomment for debugging
#   # trace_fun: fn format, args -> :io.format(format, args) end
# ]

{opts, _} =
  Api.var("MAIL_CONF")
  |> File.read!()
  |> Code.eval_string(var: &Api.var/1)

true = Process.register(self(), :mail)

send = fn %{from: from, to: to, subject: subject, body: body} ->
  res =
    :gen_smtp_client.send_blocking(
      {~c"#{from}", [~c"#{to}"],
       [
         ~c"Subject: #{subject}\r\n",
         ~c"From: #{from}\r\n",
         ~c"To: #{to}\r\n\r\n#{body}"
       ]},
      opts
    )

  IO.inspect(res: res)
end

loop = fn loop ->
  receive do
    {:send, mail} -> spawn(fn -> send.(mail) end)
    unexpected -> {:unexpected, unexpected} |> IO.inspect()
  end

  loop.(loop)
end

Api.putcast!("backend:#{Api.name()}", true)

loop.(loop)
