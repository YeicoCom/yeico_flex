defmodule Central.Utils do
  def slaves(email, true) do
    slaves = Terminal.slaves(email) ++ Terminal.slaves(nil)

    for {pid, props} <- slaves do
      {props.host, Map.put(props, :pid, pid)}
    end
    |> Enum.sort_by(fn {k, _} -> k end)
  end

  def slaves(email, false) do
    slaves = Terminal.slaves(email)

    for {pid, props} <- slaves do
      {props.host, Map.put(props, :pid, pid)}
    end
    |> Enum.sort_by(fn {k, _} -> k end)
  end
end
