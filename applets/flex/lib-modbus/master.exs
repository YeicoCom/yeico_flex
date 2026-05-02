use Terminal

exec_ = fn
  {:request, proto, cmd, tid} ->
    try do
      request = proto.({:pack_req, cmd, tid})
      length = proto.({:res_len, cmd})
      {:ok, request, length}
    rescue
      ex ->
        {:error, {:request, rescue: ex, stack: __STACKTRACE__, cmd: cmd, tid: tid}}
    end

  {:parse, proto, cmd, resp, tid} ->
    try do
      proto.({:parse_res, cmd, resp, tid})
    rescue
      ex -> {:error, {:parse, rescue: ex, stack: __STACKTRACE__, cmd: cmd, tid: tid, resp: resp}}
    end
end

open = fn opts ->
  proto = Keyword.get(opts, :proto, modbus.tcp_proto)
  trans = Keyword.get(opts, :trans, modbus.tcp_trans)
  tid = proto.({:next, nil})

  case trans.({:open, opts}) do
    {:ok, tstate} ->
      {:ok, %{trans: trans, proto: proto, tid: tid, tstate: tstate}}

    {:error, reason} ->
      {:error, reason}
  end
end

exec = fn {conn = %{trans: trans, proto: proto, tid: tid, tstate: tstate}, cmd, opts} ->
  timeout = Keyword.get(opts, :timeout, toms)
  tracer = Keyword.get(opts, :tracer, fn _, _ -> :ok end)
  conn = Map.put(conn, :tid, proto.({:next, tid}))

  with {:ok, request, length} <- exec_.({:request, proto, cmd, tid}),
       :ok <- tracer.(:output, request),
       :ok <- trans.({:write, tstate, request}),
       {:ok, resp} <- trans.({:readn, tstate, length, timeout}),
       :ok <- tracer.(:input, resp) do
    case exec_.({:parse, proto, cmd, resp, tid}) do
      {:error, error} -> {:error, conn, error}
      nil -> {:ok, conn}
      values -> {:ok, conn, values}
    end
  else
    {:error, error} ->
      {:error, conn, error}
  end
end

close = fn %{trans: trans, tstate: tstate} ->
  trans.({:close, tstate})
end

test = fn
  {:tid, conn} ->
    Map.get(conn, :tid)

  {:tid, conn, tid} ->
    Map.put(conn, :tid, tid)
end

:ok
