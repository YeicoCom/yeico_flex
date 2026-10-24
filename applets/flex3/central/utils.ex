defmodule Central.Utils do
  def slaves(admin, admin) do
    slaves = Terminal.slaves(admin) ++ Terminal.slaves(nil)

    for {pid, props} <- slaves do
      {props.host, Map.put(props, :pid, pid)}
    end
    |> Enum.sort_by(fn {k, _} -> k end)
  end

  def slaves(_admin, email) do
    slaves = Terminal.slaves(email)

    for {pid, props} <- slaves do
      {props.host, Map.put(props, :pid, pid)}
    end
    |> Enum.sort_by(fn {k, _} -> k end)
  end
end
