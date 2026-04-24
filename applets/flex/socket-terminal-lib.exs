use Terminal

isend = fn parent, data ->
  send(parent, {:socket, self(), :input, data})
end

loop = fn loop, parent, conn = %{socket: socket}, eol, buffer ->
  receive do
    {:tcp, ^socket, data} ->
      if eol do
        buffer = buffer <> data
        parts = String.split(buffer, eol)
        max = length(parts) - 1
        indexed = Enum.with_index(parts)
        Enum.each(indexed, fn {data, i} -> if(i < max, do: isend.(parent, data <> eol)) end)
        loop.(loop, parent, conn, eol, Enum.at(parts, max))
      else
        isend.(parent, buffer <> data)
        loop.(loop, parent, conn, eol, "")
      end

    {:eol, eol} ->
      if byte_size(buffer) > 0, do: isend.(parent, buffer)
      loop.(loop, parent, conn, eol, "")

    {:write, data} ->
      with :ok <- Tcp.write(conn, data) do
        loop.(loop, parent, conn, eol, buffer)
      else
        {:error, error} ->
          send(parent, {:socket, self(), :error, error: error})
          Api.warn(error: error)
      end

    unexpected ->
      send(parent, {:socket, self(), :error, unexpected: unexpected})
      Api.warn(unexpected: unexpected)
  end
end

setup = fn {parent, %{ip: ip, port: port}, eol} ->
  with {:ok, conn} <- Tcp.connect(ip, port, toms: 4_000, line: false, active: true) do
    send(parent, {:socket, self(), :success, "Connected to #{ip}:#{port}"})
    loop.(loop, parent, conn, eol, "")
  else
    {:error, error} ->
      send(parent, {:socket, self(), :error, error: error})
      Api.warn(error: error)
  end
end

omode = ["Append CR+NL", "Append CR", "Append NL", "Append None", "Hexadecimal", "Mixed"]
imode = ["Packet NL", "Packet CR", "Stream"]
options = %{omode: omode, imode: imode}

toeol = fn
  "Packet NL" -> "\n"
  "Packet CR" -> "\r"
  "Stream" -> nil
end

printable = fn line ->
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

hex2bin = fn line ->
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

mix2bin = fn line ->
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

shift = fn tzoffset, log = %{dt: dt} ->
  dt = NaiveDateTime.shift(dt, hour: tzoffset)
  dt = NaiveDateTime.to_time(dt)
  %{log | dt: dt}
end

transform = fn
  "Append CR+NL", line -> line <> "\r\n"
  "Append CR", line -> line <> "\r"
  "Append NL", line -> line <> "\n"
  "Append None", line -> line
  "Hexadecimal", line -> hex2bin.(line)
  "Mixed", line -> mix2bin.(line)
end

title = "Socket Connection"

style = fn
  :error -> "text-red-500"
  :input -> "text-blue-500"
  :output -> "text-purple-500"
  :success -> "text-lime-500"
end

initial = %{port: 44000, ip: "127.0.0.1"}

%{
  shift: shift,
  toeol: toeol,
  setup: setup,
  style: style,
  title: title,
  initial: initial,
  options: options,
  transform: transform,
  printable: printable
}
