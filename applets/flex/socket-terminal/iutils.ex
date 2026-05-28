defmodule Flex.SocketTerminal.IUtils do
  use Flex.Use.Live

  @toms 4_000
  @title "Socket Connection"
  @initial %{port: 44000, ip: "127.0.0.1"}
  @omode ["Append CR+NL", "Append CR", "Append NL", "Append None", "Hexadecimal", "Mixed"]
  @imode ["Packet NL", "Packet CR", "Stream"]
  @options %{omode: @omode, imode: @imode}

  def title, do: @title
  def initial, do: @initial
  def options, do: @options

  def transform("Append CR+NL", line), do: line <> "\r\n"
  def transform("Append CR", line), do: line <> "\r"
  def transform("Append NL", line), do: line <> "\n"
  def transform("Append None", line), do: line
  def transform("Hexadecimal", line), do: hex2bin(line)
  def transform("Mixed", line), do: mix2bin(line)

  def append(socket, state = %{logid: logid, tzoffset: tzoffset}, type, line) do
    hexa =
      case type do
        :input -> Base.encode16(line)
        :output -> Base.encode16(line)
        _ -> nil
      end

    text =
      case type do
        :input -> printable(line)
        :output -> printable(line)
        _ -> if is_binary(line), do: line, else: inspect(line)
      end

    dt = NaiveDateTime.utc_now()
    log = %{id: logid, dt: dt, style: style(type), text: text, hexa: hexa}
    log = Logs.shift(tzoffset, log)
    socket = stream(socket, :logs, [log])
    state = Map.update!(state, :logid, &(&1 + 1))
    {socket, state}
  end

  def setup opts do
    ip = Keyword.fetch!(opts, :ip)
    port = Keyword.fetch!(opts, :port)
    eol = Keyword.fetch!(opts, :imode) |> to_eol()
    parent = Keyword.fetch!(opts, :parent)

    with {:ok, conn} <- Tcp.connect(ip, port, toms: @toms, line: false, active: true) do
      send(parent, {:socket, self(), :success, "Connected to #{ip}:#{port}"})
      loop(conn, %{parent: parent, eol: eol, buffer: ""})
    else
      {:error, error} ->
        send(parent, {:socket, self(), :error, error: error})
        Log.warn(error: error)
    end
  end

  defp printable(line) do
    line
    |> String.split(~r/[[:graph:]]+/, include_captures: true)
    |> Enum.with_index()
    |> Enum.map(fn {chunk, i} ->
      case {rem(i, 2), chunk} do
        {0, ""} -> ""
        {0, chunk} -> String.duplicate(" ", byte_size(chunk))
        {1, _} -> chunk
      end
    end)
    |> Enum.join("")
  end

  defp hex2bin(line) do
    line
    |> String.split(~r/[[:xdigit:]]+/, include_captures: true)
    |> Enum.with_index()
    |> Enum.map(fn {chunk, i} ->
      case rem(i, 2) do
        0 ->
          ""

        1 ->
          len = String.length(chunk)
          len = if rem(len, 2) == 1, do: len + 1, else: len
          chunk = String.pad_leading(chunk, len, "0")
          chunk = String.upcase(chunk)
          Base.decode16!(chunk)
      end
    end)
    |> Enum.join("")
  end

  # any non hex char is considered a separator
  defp mix2bin(line) do
    line
    |> String.split(~r/\[[[:xdigit:]]+]/, include_captures: true)
    |> Enum.with_index()
    |> Enum.map(fn {chunk, i} ->
      case rem(i, 2) do
        0 ->
          chunk

        1 ->
          chunk
          |> String.trim_leading("[")
          |> String.trim_trailing("]")
          |> (fn chunk ->
                len = String.length(chunk)
                len = if rem(len, 2) == 1, do: len + 1, else: len
                String.pad_leading(chunk, len, "0")
              end).()
          |> String.upcase()
          |> Base.decode16!()
      end
    end)
    |> Enum.join("")
  end

  defp to_eol("Packet NL"), do: "\n"
  defp to_eol("Packet CR"), do: "\r"
  defp to_eol("Stream"), do: nil

  defp style(:error), do: "text-red-500"
  defp style(:input), do: "text-blue-500"
  defp style(:output), do: "text-purple-500"
  defp style(:success), do: "text-lime-500"

  defp isend(parent, data) do
    send(parent, {:socket, self(), :input, data})
  end

  defp loop(conn = %{socket: socket}, params = %{parent: parent, eol: eol, buffer: buffer}) do
    receive do
      {:tcp, ^socket, data} ->
        if eol do
          buffer = buffer <> data
          parts = String.split(buffer, eol)
          max = length(parts) - 1
          indexed = Enum.with_index(parts)
          Enum.each(indexed, fn {data, i} -> if(i < max, do: isend(parent, data <> eol)) end)
          params = Map.put(params, :buffer, Enum.at(parts, max))
          loop(conn, params)
        else
          isend(parent, buffer <> data)
          params = Map.put(params, :buffer, "")
          loop(conn, params)
        end

      {:imode, imode} ->
        if byte_size(buffer) > 0, do: isend(parent, buffer)
        params = Map.put(params, :eol, to_eol(imode))
        params = Map.put(params, :buffer, "")
        loop(conn, params)

      {:write, data} ->
        with :ok <- Tcp.write(conn, data) do
          loop(conn, params)
        else
          {:error, error} ->
            send(parent, {:socket, self(), :error, error: error})
            Log.warn(error: error)
        end

      unexpected ->
        send(parent, {:socket, self(), :error, unexpected: unexpected})
        Log.warn(unexpected: unexpected)
    end
  end
end
