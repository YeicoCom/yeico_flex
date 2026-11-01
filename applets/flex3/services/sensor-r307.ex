defmodule Flex.SensorR307 do
  use Flex.Service
  use Terminal

  defp specs(),
    do: %{
      port: %{initial: 0, check: {:integer, 0, 65_535}},
      ip: %{initial: "127.0.0.1", check: :ipv4}
    }

  defp setup(%{ip: ip, port: port}) do
    sid = Process.get(:__sid__)
    Api.debug("#{sid} run")
    {:ok, socket} = Tcp.connect(ip, port)
    clean(fn -> Tcp.close(socket) end)
    :ok = check_password(socket)
    ready()
    loop(socket)
  end

  defp loop(socket) do
    receive do
      {:req, pid, id, "PS_ReadSysPara"} ->
        send(pid, {:res, id, ps_readsyspara(socket)})

      {:req, pid, id, "PS_GetImage"} ->
        send(pid, {:res, id, ps_getimage(socket)})

      {:req, pid, id, {"PS_Image2Tz", 1}} ->
        send(pid, {:res, id, ps_image2tz(socket, 1)})

      {:req, pid, id, {"PS_Image2Tz", 2}} ->
        send(pid, {:res, id, ps_image2tz(socket, 2)})

      {:req, pid, id, {"PS_Search", start, count}}
      when is_integer(start) and start >= 0 and start <= 999 and is_integer(count) and count >= 1 and
             count <= 1000 ->
        send(pid, {:res, id, ps_search(socket, start, count)})

      {:req, pid, id, "PS_RegModel"} ->
        send(pid, {:res, id, ps_regmodel(socket)})

      {:req, pid, id, {"PS_StoreChar", index}}
      when is_integer(index) and index >= 0 and index <= 999 ->
        send(pid, {:res, id, ps_storechar(socket, index)})

      {:req, pid, id, {"PS_LoadAndUpChar", index}}
      when is_integer(index) and index >= 0 and index <= 999 ->
        send(pid, {:res, id, ps_loadandupchar(socket, index)})

      {:req, pid, id, {"PS_DeletChar", start, count}}
      when is_integer(start) and start >= 0 and start <= 999 and is_integer(count) and count >= 1 and
             count <= 1000 ->
        send(pid, {:res, id, ps_deletchar(socket, start, count)})

      {:req, pid, id, {"PS_DownAndStoreChar", index, data}}
      when is_integer(index) and index >= 0 and index <= 999 and is_binary(data) ->
        send(pid, {:res, id, ps_downandstorechar(socket, index, data)})

      unexpected ->
        Log.trace(unexpected: unexpected)
    end

    # detect socket closed
    :ok = check_password(socket)

    loop(socket)
  end

  # erlang binary pattern match is big endian by default
  @prefix1 "EF 01 FF FF FF FF"
  @prefix2 <<239, 1, 255, 255, 255, 255>>
  @errors %{
    0x00 => "Command execution complete",
    0x01 => "Error when receiving data package",
    0x02 => "No finger on the sensor",
    0x03 => "Fail to enroll the finger",
    0x04 => "Fail to generate character file due to the over-disorderly fingerprint image",
    0x05 => "Fail to generate character file due to the over-wet fingerprint image",
    0x06 => "Fail to generate character file due to the over-disorderly fingerprint image",
    0x07 =>
      "Fail to generate character file due to lackness of character point or over-smallness of fingerprint image",
    0x08 => "Finger doesn’t match",
    0x09 => "Fail to find the matching finger",
    0x0A => "Fail to combine the character files",
    0x0B => "Addressing PageID is beyond the finger library",
    0x0C => "Error when reading template from library or the template is invalid",
    0x0D => "Error when uploading template",
    0x0E => "Module can’t receive the following data packages",
    0x0F => "Error when uploading image",
    0x10 => "Fail to delete the template",
    0x11 => "Fail to clear finger library",
    0x13 => "Wrong password!",
    0x15 => "Fail to generate the image for the lackness of valid primary image",
    0x18 => "Error when writing flash",
    0x19 => "No definition error",
    0x1A => "Invalid register number",
    0x1B => "Incorrect configuration of register",
    0x1C => "Wrong notepad page number",
    0x1D => "Fail to operate the communication port",
    0x41 => "No finger on sensor when add fingerprint on second time",
    0x42 => "Fail to enroll the finger for second fingerprint add",
    0x43 =>
      "Fail to generate character file due to lackness of character point or over-smallness of fingerprint image for second fingerprint add",
    0x44 =>
      "Fail to generate character file due to the over-disorderly fingerprint image for second fingerprint add",
    0x45 => "Duplicate fingerprint"
  }

  defp check_password(socket) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 07 13 00 00 00 00 00 1B") do
      read_response(socket)
    end
  end

  defp ps_readsyspara(socket) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 03 0F 00 13"),
         {:ok, {res28 = <<_::binary-size(9)>> <> <<data::binary-size(17)>> <> _cs, <<>>}} <-
           read_n(socket, 28),
         :ok <- checksum(res28) do
      <<
        _::8,
        status::16,
        system_id::16,
        library_size::16,
        security_level::16,
        device_address::binary-size(4),
        packet_size_code::16,
        baud_setting::16
      >> = data

      packet_size_bytes =
        case packet_size_code do
          0 -> 32
          1 -> 64
          2 -> 128
          3 -> 256
          _ -> :unknown
        end

      {:ok,
       %{
         status_register: status,
         system_id: system_id,
         library_size: library_size,
         security_level: security_level,
         device_address: device_address |> Base.encode16(),
         baud_rate: baud_setting * 9600,
         packet_size_code: packet_size_code,
         packet_size_bytes: packet_size_bytes
       }}
    else
      unexpected -> else_error(unexpected)
    end
  end

  defp ps_getimage(socket) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 03 01 00 05") do
      read_response(socket)
    end
  end

  defp ps_image2tz(socket, 1) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 04 02 01 00 08") do
      read_response(socket)
    end
  end

  defp ps_image2tz(socket, 2) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 04 02 02 00 09") do
      read_response(socket)
    end
  end

  defp ps_search(socket, start, count) do
    cs =
      14 + Bitwise.band(start, 0xFF) + Bitwise.bsr(start, 8) + Bitwise.band(count, 0xFF) +
        Bitwise.bsr(count, 8)

    hex1 = Base.encode16(<<start::16>>)
    hex2 = Base.encode16(<<count::16>>)
    hex3 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 08 04 01" <> hex1 <> hex2 <> hex3),
         {:ok,
          {res16 = @prefix2 <> <<7, 0, 7>> <> <<code>> <> <<page::16>> <> <<score::16>> <> _cs,
           <<>>}} <- read_n(socket, 16),
         :ok <- checksum(res16) do
      case code do
        0 ->
          {:ok, %{page: page, score: score, pass: score >= 50, cond: ">= 50"}}

        _ ->
          err = @errors[code] || "Unknown error"
          {:error, "#{code} #{err}"}
      end
    else
      unexpected -> else_error(unexpected)
    end
  end

  defp ps_regmodel(socket) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 03 05 00 09") do
      read_response(socket)
    end
  end

  defp ps_storechar(socket, index) do
    cs = 14 + Bitwise.band(index, 0xFF) + Bitwise.bsr(index, 8)
    hex1 = Base.encode16(<<index::16>>)
    hex2 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 06 06 01" <> hex1 <> hex2) do
      read_response(socket)
    end
  end

  defp ps_deletchar(socket, start, count) do
    cs =
      20 + Bitwise.band(start, 0xFF) + Bitwise.bsr(start, 8) + Bitwise.band(count, 0xFF) +
        Bitwise.bsr(count, 8)

    hex1 = Base.encode16(<<start::16>>)
    hex2 = Base.encode16(<<count::16>>)
    hex3 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 07 0C" <> hex1 <> hex2 <> hex3) do
      read_response(socket)
    end
  end

  defp ps_downandstorechar(socket, index, data) do
    with {:ok, %{packet_size_bytes: size}} when is_integer(size) <- ps_readsyspara(socket),
         :ok <- send_hexstr(socket, @prefix1 <> "01 00 04 09 01 00 0F"),
         :ok <- read_response(socket),
         n <- div(byte_size(data), size),
         0 <- rem(byte_size(data), size),
         {:ok, ""} <- send_block(socket, data, n, size),
         :ok <- ps_storechar(socket, index) do
      :ok
    else
      unexpected -> else_error(unexpected)
    end
  end

  defp send_block(socket, data, n, size) do
    for i <- 0..(n - 1)//1, reduce: {:ok, data} do
      {:ok, data} ->
        fid = if i < n - 1, do: 2, else: 8
        <<frame::binary-size(size)>> <> tail = data
        cs = fid + Bitwise.band(size + 2, 0xFF) + Bitwise.bsr(size + 2, 8)

        cs =
          for <<byte <- frame>>, reduce: cs do
            acc -> acc + byte
          end

        cs = Bitwise.band(cs, 0xFFFF)
        res = Tcp.write(socket, @prefix2 <> <<fid>> <> <<size + 2::16>> <> frame <> <<cs::16>>)
        {res, tail}

      unexpected ->
        unexpected
    end
  end

  defp ps_loadandupchar(socket, index) do
    cs = 15 + Bitwise.band(index, 0xFF) + Bitwise.bsr(index, 8)
    hex1 = Base.encode16(<<index::16>>)
    hex2 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 06 07 01" <> hex1 <> hex2),
         :ok <- read_response(socket),
         :ok <- send_hexstr(socket, @prefix1 <> "01 00 04 08 01 00 0E") do
      read_block(socket)
    end
  end

  defp read_block(socket, acc \\ nil)

  defp read_block(socket, nil) do
    with {:ok, {res12, tail}} <- read_n(socket, 12),
         :ok <- checksum(res12),
         {:ok, {res9, tail}} <- read_n(socket, 9, tail) do
      read_block(socket, {res9, [], tail})
    else
      unexpected -> else_error(unexpected)
    end
  end

  defp read_block(socket, {res9 = @prefix2 <> <<02>> <> <<len::16>>, acc, tail}) do
    with {:ok, {data, tail}} <- read_n(socket, len, tail),
         :ok <- checksum(res9 <> data),
         {:ok, {res9, tail}} <- read_n(socket, 9, tail),
         <<data::binary-size(len - 2)>> <> _cs = data do
      read_block(socket, {res9, [acc, data], tail})
    end
  end

  defp read_block(socket, {res9 = @prefix2 <> <<08>> <> <<len::16>>, acc, tail}) do
    with {:ok, {data, <<>>}} <- read_n(socket, len, tail),
         :ok <- checksum(res9 <> data),
         <<data::binary-size(len - 2)>> <> _cs = data do
      {:ok, [acc, data] |> IO.iodata_to_binary()}
    end
  end

  defp read_response(socket) do
    with {:ok, {res12, <<>>}} <- read_n(socket, 12),
         @prefix2 <> <<07, 00, 03>> <> <<res>> <> _cs <- res12,
         :ok <- checksum(res12) do
      case res do
        0 ->
          :ok

        _ ->
          err = @errors[res] || "Unknown error"
          {:error, "#{res} #{err}"}
      end
    else
      unexpected -> else_error(unexpected)
    end
  end

  defp else_error({:error, error}), do: {:error, error}
  defp else_error({:ok, unexpected}), do: {:error, unexpected: unexpected}
  defp else_error(unexpected), do: {:error, unexpected: unexpected}

  defp read_n(_socket, n, acc \\ <<>>)

  defp read_n(_socket, n, acc) when byte_size(acc) >= n do
    <<datan::binary-size(n), tail::binary>> = acc
    {:ok, {datan, tail}}
  end

  defp read_n(socket, n, acc) when byte_size(acc) < n do
    with {:ok, data} <- Tcp.read(socket, 2_000) do
      read_n(socket, n, acc <> data)
    end
  end

  defp checksum(data) do
    n = byte_size(data) - 6 - 2

    with @prefix2 <> <<sumable::binary-size(n)>> <> <<csr::16>> <- data do
      csc =
        for <<byte <- sumable>>, reduce: 0 do
          acc -> acc + byte
        end

      case csr == csc do
        true -> :ok
        _ -> {:error, "checksum mismatch"}
      end
    end
  end

  defp parse_hexstr(hexstr) do
    hexstr
    |> String.replace(" ", "")
    |> Base.decode16!(case: :upper)
  end

  defp send_hexstr(socket, hexstr) do
    Tcp.write(socket, parse_hexstr(hexstr))
  end
end
