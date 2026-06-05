defmodule Flex2.Utils do
  # https://hexdocs.pm/elixir/Inspect.Opts.html
  @inspect [limit: :infinity, printable_limit: :infinity, width: :infinity]

  def path(route), do: Applet.path(route)
  def fpath(path), do: Terminal.fpath(path)
  def dpath(path), do: Terminal.dpath(path)
  def dropcast!(key), do: Applet.Api.dropcast!(key)
  def putcast!(key, value), do: Applet.Api.putcast!(key, value)

  def id(), do: UUID.uuid1() |> ShortUUID.encode!()
  def expand(path), do: Terminal.expand(path)

  def sleep(), do: Process.sleep(:infinity)
  def sleep(millis), do: Process.sleep(millis)

  def inspect?(term) when is_binary(term), do: term
  def inspect?(term), do: inspect(term, @inspect)

  def pid(%Task{pid: pid}), do: pid

  # Api.await sleeps at least one cycle
  def pid(module) when is_atom(module) do
    case Process.whereis(module) do
      pid when is_pid(pid) ->
        pid

      _ ->
        Process.sleep(10)
        pid(module)
    end
  end

  # Task.await forwards exit signals making it not suitable for loops
  def await(%Task{ref: ref, owner: owner} = task) do
    if owner != self(), do: throw(%{error: "only owner can await", caller: self(), owner: owner})

    receive do
      {^ref, reply} ->
        Process.demonitor(ref, [:flush])
        {:ok, reply}

      {:DOWN, ^ref, _, proc, reason} ->
        {:error, %{error: :down, reason: reason, proc: proc, task: task}}
    end
  end

  def kill(%Task{pid: pid}), do: kill(pid)

  def kill(pid) when is_pid(pid) do
    Process.unlink(pid)
    Process.exit(pid, :kill)
    ref = Process.monitor(pid)

    receive do
      {:DOWN, ^ref, _, ^pid, _} -> :ok
    end

    # not a reference
    # Process.demonitor(pid)
  end

  # for Flex2.Cli
  def kill?(name) do
    case whereis?(name) do
      nil ->
        :nop

      pid ->
        kill(pid)
        pid
    end
  end

  def stamp() do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:millisecond)
    |> NaiveDateTime.to_iso8601()
    |> String.replace("-", "")
    |> String.replace(":", "")
  end

  def safe(fun) when is_function(fun, 0) do
    try do
      {:ok, fun.()}
    rescue
      error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
    catch
      error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
    end
  end

  def safe(fun, arg) when is_function(fun, 1) do
    try do
      {:ok, fun.(arg)}
    rescue
      error -> {:error, %{type: :rescue, error: error, stack: __STACKTRACE__}}
    catch
      error -> {:error, %{type: :catch, error: error, stack: __STACKTRACE__}}
    end
  end

  def receive(), do: receive(do: (msg -> msg))

  def receive(msg), do: receive(do: (^msg -> :ok))

  def flush() do
    receive do
      _ -> flush()
    after
      0 -> :ok
    end
  end

  def flush(toms) do
    receive do
      _ -> flush(toms)
    after
      toms -> :ok
    end
  end

  def whereis(pid_or_name) when is_pid(pid_or_name), do: pid_or_name

  def whereis(pid_or_name) when is_binary(pid_or_name) do
    case Applet.Api.Udb.lookup({:entity, pid_or_name}) do
      [] ->
        Process.sleep(100)
        whereis(pid_or_name)

      [{pid, _}] ->
        pid
    end
  end

  # for Flex2.Cli
  def whereis?(name) when is_binary(name) do
    case Applet.Api.Udb.lookup({:entity, name}) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def hostname() do
    {:ok, host} = :inet.gethostname()
    to_string(host)
  end

  def hostname_f() do
    {hostname, 0} = System.cmd("hostname", ["-f"])
    hostname |> String.trim()
  end

  def resolve(host) do
    with {:ok, {a, b, c, d}} <- :inet.getaddr(~c"#{host}", :inet) do
      {:ok, "#{a}.#{b}.#{c}.#{d}"}
    end
  end

  def until(fun, dms \\ 100) do
    case safe(fun) do
      {:ok, true} -> :ok
      _ -> until(fun, dms)
    end
  end

  def md5(text) do
    :crypto.hash(:md5, text)
    |> Base.encode16(case: :lower)
  end
end
