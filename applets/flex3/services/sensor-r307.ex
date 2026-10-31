defmodule Flex.SensorR307 do
  use Flex.Service
  use Terminal

  # Capture image if finger present
  # Flex.Service.call("r307_sensor", "PS_GetImage")
  # {:error, "2 No finger on the sensor"}
  # Store captured image in buffer 1
  # Flex.Service.call("r307_sensor", {"PS_Image2Tz", 1})
  # Capture image if finger present
  # Flex.Service.call("r307_sensor", "PS_GetImage")
  # Store captured image in buffer 2
  # Flex.Service.call("r307_sensor", {"PS_Image2Tz", 2})
  # Generate model from buffer 1 and 2
  # Flex.Service.call("r307_sensor", "PS_RegModel")
  # Store model to flash at index n (0-999)
  # Flex.Service.call("r307_sensor", {"PS_StoreChar", n})
  # Flex.Service.call("r307_sensor", {"PS_StoreChar", 0})
  # Flex.Service.call("r307_sensor", {"PS_StoreChar", 1})
  # Load model from flash at index n (0-999)
  # Flex.Service.call("r307_sensor", {"PS_LoadAndUpChar", 0})
  # Flex.Service.call("r307_sensor", {"PS_LoadAndUpChar", 1})

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
    {:ok, 0} = check_password(socket)
    ready()
    loop(socket)
  end

  defp loop(socket) do
    receive do
      {:req, pid, id, "PS_GetImage"} ->
        send(pid, {:res, id, ps_getimage(socket)})

      {:req, pid, id, {"PS_Image2Tz", 1}} ->
        send(pid, {:res, id, ps_image2tz(socket, 1)})

      {:req, pid, id, {"PS_Image2Tz", 2}} ->
        send(pid, {:res, id, ps_image2tz(socket, 2)})

      {:req, pid, id, "PS_RegModel"} ->
        send(pid, {:res, id, ps_regmodel(socket)})

      {:req, pid, id, {"PS_StoreChar", n}} when is_integer(n) and n >= 0 and n <= 999 ->
        send(pid, {:res, id, ps_storechar(socket, n)})

      {:req, pid, id, {"PS_LoadAndUpChar", n}} when is_integer(n) and n >= 0 and n <= 999 ->
        send(pid, {:res, id, ps_loadandupchar(socket, n)})

      unexpected ->
        Log.trace(unexpected: unexpected)
    end

    # detect socket closed
    {:ok, 0} = check_password(socket)

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

  defp ps_regmodel(socket) do
    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 03 05 00 09") do
      read_response(socket)
    end
  end

  defp ps_storechar(socket, n) do
    cs = 14 + Bitwise.band(n, 0xFF) + Bitwise.bsr(n, 8)
    hex1 = Base.encode16(<<n::16>>)
    hex2 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 06 06 01" <> hex1 <> hex2) do
      read_response(socket)
    end
  end

  defp ps_loadandupchar(socket, n) do
    cs = 15 + Bitwise.band(n, 0xFF) + Bitwise.bsr(n, 8)
    hex1 = Base.encode16(<<n::16>>)
    hex2 = Base.encode16(<<cs::16>>)

    with :ok <- send_hexstr(socket, @prefix1 <> "01 00 06 07 01" <> hex1 <> hex2),
         {:ok, 0} <- read_response(socket),
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
          {:ok, res}

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
