# from https://github.com/YeicoCom/yeico_modbus/tree/main/lib
# changes
# - @toms 4000
# - exec opts for tracer for modbus terminal
# - added protocol id function

defmodule Modbus.Crc do
  @moduledoc false

  @hi """
      [
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
        0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
        0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01,
        0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81,
        0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0,
        0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01,
        0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
        0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
        0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01,
        0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
        0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0,
        0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01,
        0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81, 0x40, 0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41,
        0x00, 0xC1, 0x81, 0x40, 0x01, 0xC0, 0x80, 0x41, 0x01, 0xC0, 0x80, 0x41, 0x00, 0xC1, 0x81,
        0x40
      ]
      """
      |> Code.eval_string()
      |> elem(0)
      |> :array.from_list()

  @lo """
      [
      0x00, 0xC0, 0xC1, 0x01, 0xC3, 0x03, 0x02, 0xC2, 0xC6, 0x06, 0x07, 0xC7, 0x05, 0xC5, 0xC4,
      0x04, 0xCC, 0x0C, 0x0D, 0xCD, 0x0F, 0xCF, 0xCE, 0x0E, 0x0A, 0xCA, 0xCB, 0x0B, 0xC9, 0x09,
      0x08, 0xC8, 0xD8, 0x18, 0x19, 0xD9, 0x1B, 0xDB, 0xDA, 0x1A, 0x1E, 0xDE, 0xDF, 0x1F, 0xDD,
      0x1D, 0x1C, 0xDC, 0x14, 0xD4, 0xD5, 0x15, 0xD7, 0x17, 0x16, 0xD6, 0xD2, 0x12, 0x13, 0xD3,
      0x11, 0xD1, 0xD0, 0x10, 0xF0, 0x30, 0x31, 0xF1, 0x33, 0xF3, 0xF2, 0x32, 0x36, 0xF6, 0xF7,
      0x37, 0xF5, 0x35, 0x34, 0xF4, 0x3C, 0xFC, 0xFD, 0x3D, 0xFF, 0x3F, 0x3E, 0xFE, 0xFA, 0x3A,
      0x3B, 0xFB, 0x39, 0xF9, 0xF8, 0x38, 0x28, 0xE8, 0xE9, 0x29, 0xEB, 0x2B, 0x2A, 0xEA, 0xEE,
      0x2E, 0x2F, 0xEF, 0x2D, 0xED, 0xEC, 0x2C, 0xE4, 0x24, 0x25, 0xE5, 0x27, 0xE7, 0xE6, 0x26,
      0x22, 0xE2, 0xE3, 0x23, 0xE1, 0x21, 0x20, 0xE0, 0xA0, 0x60, 0x61, 0xA1, 0x63, 0xA3, 0xA2,
      0x62, 0x66, 0xA6, 0xA7, 0x67, 0xA5, 0x65, 0x64, 0xA4, 0x6C, 0xAC, 0xAD, 0x6D, 0xAF, 0x6F,
      0x6E, 0xAE, 0xAA, 0x6A, 0x6B, 0xAB, 0x69, 0xA9, 0xA8, 0x68, 0x78, 0xB8, 0xB9, 0x79, 0xBB,
      0x7B, 0x7A, 0xBA, 0xBE, 0x7E, 0x7F, 0xBF, 0x7D, 0xBD, 0xBC, 0x7C, 0xB4, 0x74, 0x75, 0xB5,
      0x77, 0xB7, 0xB6, 0x76, 0x72, 0xB2, 0xB3, 0x73, 0xB1, 0x71, 0x70, 0xB0, 0x50, 0x90, 0x91,
      0x51, 0x93, 0x53, 0x52, 0x92, 0x96, 0x56, 0x57, 0x97, 0x55, 0x95, 0x94, 0x54, 0x9C, 0x5C,
      0x5D, 0x9D, 0x5F, 0x9F, 0x9E, 0x5E, 0x5A, 0x9A, 0x9B, 0x5B, 0x99, 0x59, 0x58, 0x98, 0x88,
      0x48, 0x49, 0x89, 0x4B, 0x8B, 0x8A, 0x4A, 0x4E, 0x8E, 0x8F, 0x4F, 0x8D, 0x4D, 0x4C, 0x8C,
      0x44, 0x84, 0x85, 0x45, 0x87, 0x47, 0x46, 0x86, 0x82, 0x42, 0x43, 0x83, 0x41, 0x81, 0x80,
      0x40
      ]
      """
      |> Code.eval_string()
      |> elem(0)
      |> :array.from_list()

  def crc(data) do
    crc(data, 0xFF, 0xFF)
  end

  defp crc(<<>>, hi, lo), do: <<hi, lo>>

  defp crc(data, hi, lo) do
    <<first, tail::binary>> = data
    index = Bitwise.bxor(lo, first)
    nhi = :array.get(index, @hi)
    lo = Bitwise.bxor(hi, nhi)
    crc(tail, :array.get(index, @lo), lo)
  end
end

defmodule Modbus.Utils do
  @moduledoc false

  def byte_count(count) do
    div(count - 1, 8) + 1
  end

  def bool_to_byte(value) do
    # enforce 0 or 1 only
    case value do
      0 -> 0x00
      1 -> 0xFF
    end
  end

  def bin_to_bitlist(count, <<b7::1, b6::1, b5::1, b4::1, b3::1, b2::1, b1::1, b0::1>>)
      when count <= 8 do
    Enum.take([b0, b1, b2, b3, b4, b5, b6, b7], count)
  end

  def bin_to_bitlist(
        count,
        <<b7::1, b6::1, b5::1, b4::1, b3::1, b2::1, b1::1, b0::1, tail::binary>>
      ) do
    [b0, b1, b2, b3, b4, b5, b6, b7] ++ bin_to_bitlist(count - 8, tail)
  end

  def bin_to_reglist(1, <<register::16>>) do
    [register]
  end

  def bin_to_reglist(count, <<register::16, tail::binary>>) do
    [register | bin_to_reglist(count - 1, tail)]
  end

  def bitlist_to_bin(values) do
    lists = Enum.chunk_every(values, 8, 8, [0, 0, 0, 0, 0, 0, 0, 0])

    list =
      for list8 <- lists do
        [v0, v1, v2, v3, v4, v5, v6, v7] =
          for b <- list8 do
            # enforce 0 or 1 only
            bool_to_byte(b)
          end

        <<v7::1, v6::1, v5::1, v4::1, v3::1, v2::1, v1::1, v0::1>>
      end

    :erlang.iolist_to_binary(list)
  end

  def reglist_to_bin(values) do
    list =
      for value <- values do
        <<value::size(16)>>
      end

    :erlang.iolist_to_binary(list)
  end
end

defmodule Modbus.Request do
  @moduledoc false
  alias Modbus.Utils

  def pack({:rc, slave, address, count}) do
    reads(:d, slave, 1, address, count)
  end

  def pack({:ri, slave, address, count}) do
    reads(:d, slave, 2, address, count)
  end

  def pack({:rhr, slave, address, count}) do
    reads(:a, slave, 3, address, count)
  end

  def pack({:rir, slave, address, count}) do
    reads(:a, slave, 4, address, count)
  end

  def pack({:fc, slave, address, value}) when is_integer(value) do
    write(:d, slave, 5, address, value)
  end

  def pack({:phr, slave, address, value}) when is_integer(value) do
    write(:a, slave, 6, address, value)
  end

  def pack({:fc, slave, address, values}) when is_list(values) do
    writes(:d, slave, 15, address, values)
  end

  def pack({:phr, slave, address, values}) when is_list(values) do
    writes(:a, slave, 16, address, values)
  end

  def parse(<<slave, 1, address::16, count::16>>) do
    {:rc, slave, address, count}
  end

  def parse(<<slave, 2, address::16, count::16>>) do
    {:ri, slave, address, count}
  end

  def parse(<<slave, 3, address::16, count::16>>) do
    {:rhr, slave, address, count}
  end

  def parse(<<slave, 4, address::16, count::16>>) do
    {:rir, slave, address, count}
  end

  def parse(<<slave, 5, address::16, 0x00, 0x00>>) do
    {:fc, slave, address, 0}
  end

  def parse(<<slave, 5, address::16, 0xFF, 0x00>>) do
    {:fc, slave, address, 1}
  end

  def parse(<<slave, 6, address::16, value::16>>) do
    {:phr, slave, address, value}
  end

  def parse(<<slave, 15, address::16, count::16, bytes, data::binary>>) do
    ^bytes = Utils.byte_count(count)
    values = Utils.bin_to_bitlist(count, data)
    {:fc, slave, address, values}
  end

  def parse(<<slave, 16, address::16, count::16, bytes, data::binary>>) do
    ^bytes = 2 * count
    values = Utils.bin_to_reglist(count, data)
    {:phr, slave, address, values}
  end

  def length({:rc, _slave, _address, _count}) do
    6
  end

  def length({:ri, _slave, _address, _count}) do
    6
  end

  def length({:rhr, _slave, _address, _count}) do
    6
  end

  def length({:rir, _slave, _address, _count}) do
    6
  end

  def length({:fc, _slave, _address, value}) when is_integer(value) do
    6
  end

  def length({:phr, _slave, _address, value}) when is_integer(value) do
    6
  end

  def length({:fc, _slave, _address, values}) when is_list(values) do
    7 + Utils.byte_count(Enum.count(values))
  end

  def length({:phr, _slave, _address, values}) when is_list(values) do
    7 + 2 * Enum.count(values)
  end

  defp reads(_type, slave, function, address, count) do
    <<slave, function, address::16, count::16>>
  end

  defp write(:d, slave, function, address, value) do
    <<slave, function, address::16, Utils.bool_to_byte(value), 0x00>>
  end

  defp write(:a, slave, function, address, value) do
    <<slave, function, address::16, value::16>>
  end

  defp writes(:d, slave, function, address, values) do
    count = Enum.count(values)
    bytes = Utils.byte_count(count)
    data = Utils.bitlist_to_bin(values)
    <<slave, function, address::16, count::16, bytes, data::binary>>
  end

  defp writes(:a, slave, function, address, values) do
    count = Enum.count(values)
    bytes = 2 * count
    data = Utils.reglist_to_bin(values)
    <<slave, function, address::16, count::16, bytes, data::binary>>
  end
end

defmodule Modbus.Response do
  @moduledoc false
  alias Modbus.Utils

  def pack({:rc, slave, _address, count}, values) do
    ^count = Enum.count(values)
    data = Utils.bitlist_to_bin(values)
    reads(slave, 1, data)
  end

  def pack({:ri, slave, _address, count}, values) do
    ^count = Enum.count(values)
    data = Utils.bitlist_to_bin(values)
    reads(slave, 2, data)
  end

  def pack({:rhr, slave, _address, count}, values) do
    ^count = Enum.count(values)
    data = Utils.reglist_to_bin(values)
    reads(slave, 3, data)
  end

  def pack({:rir, slave, _address, count}, values) do
    ^count = Enum.count(values)
    data = Utils.reglist_to_bin(values)
    reads(slave, 4, data)
  end

  def pack({:fc, slave, address, value}, nil) when is_integer(value) do
    write(:d, slave, 5, address, value)
  end

  def pack({:phr, slave, address, value}, nil) when is_integer(value) do
    write(:a, slave, 6, address, value)
  end

  def pack({:fc, slave, address, values}, nil) when is_list(values) do
    writes(:d, slave, 15, address, values)
  end

  def pack({:phr, slave, address, values}, nil) when is_list(values) do
    writes(:a, slave, 16, address, values)
  end

  def parse({:rc, slave, _address, count}, <<slave, 1, bytes, data::binary>>) do
    ^bytes = Utils.byte_count(count)
    Utils.bin_to_bitlist(count, data)
  end

  def parse({:ri, slave, _address, count}, <<slave, 2, bytes, data::binary>>) do
    ^bytes = Utils.byte_count(count)
    Utils.bin_to_bitlist(count, data)
  end

  def parse({:rhr, slave, _address, count}, <<slave, 3, bytes, data::binary>>) do
    ^bytes = 2 * count
    Utils.bin_to_reglist(count, data)
  end

  def parse({:rir, slave, _address, count}, <<slave, 4, bytes, data::binary>>) do
    ^bytes = 2 * count
    Utils.bin_to_reglist(count, data)
  end

  def parse({:fc, slave, address, 0}, <<slave, 5, address::16, 0x00, 0x00>>) do
    nil
  end

  def parse({:fc, slave, address, 1}, <<slave, 5, address::16, 0xFF, 0x00>>) do
    nil
  end

  def parse({:phr, slave, address, value}, <<slave, 6, address::16, value::16>>) do
    nil
  end

  def parse({:fc, slave, address, values}, <<slave, 15, address::16, count::16>>) do
    ^count = Enum.count(values)
    nil
  end

  def parse({:phr, slave, address, values}, <<slave, 16, address::16, count::16>>) do
    ^count = Enum.count(values)
    nil
  end

  def length({:rc, _slave, _address, count}) do
    3 + Utils.byte_count(count)
  end

  def length({:ri, _slave, _address, count}) do
    3 + Utils.byte_count(count)
  end

  def length({:rhr, _slave, _address, count}) do
    3 + 2 * count
  end

  def length({:rir, _slave, _address, count}) do
    3 + 2 * count
  end

  def length({:fc, _slave, _address, _}) do
    6
  end

  def length({:phr, _slave, _address, _}) do
    6
  end

  defp reads(slave, function, data) do
    bytes = :erlang.byte_size(data)
    <<slave, function, bytes, data::binary>>
  end

  defp write(:d, slave, function, address, value) do
    <<slave, function, address::16, Utils.bool_to_byte(value), 0x00>>
  end

  defp write(:a, slave, function, address, value) do
    <<slave, function, address::16, value::16>>
  end

  defp writes(_type, slave, function, address, values) do
    count = Enum.count(values)
    <<slave, function, address::16, count::16>>
  end
end

defmodule Modbus.Protocol do
  @moduledoc false
  @callback id() :: binary()
  @callback next(tid :: any()) :: any()
  @callback pack_req(cmd :: tuple(), tid :: any) :: req :: binary()
  @callback res_len(cmd :: tuple()) :: len :: integer()
  @callback parse_res(cmd :: tuple(), res :: binary(), tid :: any) :: list(integer())
  @callback parse_req(req :: binary()) :: {cmd :: tuple(), tid :: any}
  @callback pack_res(cmd :: tuple(), values :: list(integer()), tid :: any) :: req :: binary()

  def id(mod) do
    mod.id()
  end

  def next(mod, tid) do
    mod.next(tid)
  end

  def pack_req(mod, cmd, tid) do
    mod.pack_req(cmd, tid)
  end

  def res_len(mod, cmd) do
    mod.res_len(cmd)
  end

  def parse_res(mod, cmd, res, tid) do
    mod.parse_res(cmd, res, tid)
  end

  def parse_req(mod, req) do
    mod.parse_req(req)
  end

  def pack_res(mod, cmd, values, tid) do
    mod.pack_res(cmd, values, tid)
  end
end

defmodule Modbus.Rtu.Protocol do
  @moduledoc false
  @behaviour Modbus.Protocol
  alias __MODULE__.Wrapper
  alias Modbus.Request
  alias Modbus.Response
  alias Modbus.Crc

  def id do
    "RTU"
  end

  def next(_) do
    nil
  end

  def pack_req(cmd, _tid \\ nil) do
    cmd |> Request.pack() |> Wrapper.wrap()
  end

  def res_len(cmd) do
    Response.length(cmd) + 2
  end

  def parse_res(cmd, wraped, _tid \\ nil) do
    Response.parse(cmd, wraped |> Wrapper.unwrap())
  end

  def parse_req(wraped) do
    {wraped |> Wrapper.unwrap() |> Request.parse(), nil}
  end

  def pack_res(cmd, values, _tid \\ nil) do
    cmd |> Response.pack(values) |> Wrapper.wrap()
  end

  defmodule Wrapper do
    @moduledoc false
    # CRC is little endian
    # http://modbus.org/docs/Modbus_over_serial_line_V1_02.pdf page 13
    def wrap(payload) do
      <<crc_hi, crc_lo>> = Crc.crc(payload)
      <<payload::binary, crc_lo, crc_hi>>
    end

    # CRC is little endian
    # http://modbus.org/docs/Modbus_over_serial_line_V1_02.pdf page 13
    def unwrap(data) do
      size = :erlang.byte_size(data) - 2
      <<payload::binary-size(size), crc_lo, crc_hi>> = data
      <<^crc_hi, ^crc_lo>> = Crc.crc(payload)
      payload
    end
  end
end

defmodule Modbus.Tcp.Protocol do
  @moduledoc false
  @behaviour Modbus.Protocol
  alias __MODULE__.Wrapper
  alias Modbus.Request
  alias Modbus.Response
  import Bitwise

  def id do
    "TCP"
  end

  def next(tid) do
    case tid do
      nil -> 0
      _ -> band(tid + 1, 0xFFFF)
    end
  end

  def pack_req(cmd, tid) do
    cmd |> Request.pack() |> Wrapper.wrap(tid)
  end

  def res_len(cmd) do
    Response.length(cmd) + 6
  end

  def parse_res(cmd, wraped, tid) do
    Response.parse(cmd, wraped |> Wrapper.unwrap(tid))
  end

  def parse_req(wraped) do
    {pack, transid} = wraped |> Wrapper.unwrap()
    {pack |> Request.parse(), transid}
  end

  def pack_res(cmd, values, tid) do
    cmd |> Response.pack(values) |> Wrapper.wrap(tid)
  end

  defmodule Wrapper do
    @moduledoc false
    def wrap(payload, tid) do
      size = :erlang.byte_size(payload)
      <<tid::16, 0, 0, size::16, payload::binary>>
    end

    def unwrap(<<tid::16, 0, 0, size::16, payload::binary>>, tid) do
      ^size = :erlang.byte_size(payload)
      payload
    end

    def unwrap(<<tid::16, 0, 0, size::16, payload::binary>>) do
      ^size = :erlang.byte_size(payload)
      {payload, tid}
    end
  end
end

defmodule Modbus.Transport do
  @moduledoc false
  @callback open(opts :: keyword()) ::
              {:ok, conn :: any()} | {:error, reason :: any()}
  @callback readp(conn :: any()) :: {:ok, packet :: binary()} | {:error, reason :: any()}
  @callback readn(conn :: any(), count :: integer(), timeout :: integer()) ::
              {:ok, packet :: binary()} | {:error, reason :: any()}
  @callback write(conn :: any(), packet :: binary()) :: :ok | {:error, reason :: any()}
  @callback close(conn :: any()) :: :ok | {:error, reason :: any()}

  def open(mod, opts) when is_atom(mod) do
    mod.open(opts)
  end

  def open(mod, opts) when is_function(mod, 1) do
    mod.({:open, opts})
  end

  def readn({mod, conn}, count, timeout) when is_atom(mod) do
    mod.readn(conn, count, timeout)
  end

  def readn({mod, conn}, count, timeout) when is_function(mod, 1) do
    mod.({:readn, conn, count, timeout})
  end

  def readp({mod, conn}) when is_atom(mod) do
    mod.readp(conn)
  end

  def readp({mod, conn}) when is_function(mod, 1) do
    mod.({:readp, conn})
  end

  def write({mod, conn}, packet) when is_atom(mod) do
    mod.write(conn, packet)
  end

  def write({mod, conn}, packet) when is_function(mod, 1) do
    mod.({:write, conn, packet})
  end

  def close({mod, conn}) when is_atom(mod) do
    mod.close(conn)
  end

  def close({mod, conn}) when is_function(mod, 1) do
    mod.({:close, conn})
  end
end

defmodule Modbus.Tcp.Transport do
  @moduledoc false
  @behaviour Modbus.Transport
  @toms 4000

  def open(opts) do
    ip = Keyword.fetch!(opts, :ip)
    ip = if is_binary(ip), do: parse(ip), else: ip
    port = Keyword.fetch!(opts, :port)
    timeout = Keyword.get(opts, :timeout, @toms)
    opts = [:binary, packet: :raw, active: false]
    :gen_tcp.connect(ip, port, opts, timeout)
  end

  def readn(socket, count, timeout) do
    :gen_tcp.recv(socket, count, timeout)
  end

  def readp(socket) do
    :gen_tcp.recv(socket, 0)
  end

  def write(socket, packet) do
    # discard before send
    :gen_tcp.recv(socket, 0, 0)
    :gen_tcp.send(socket, packet)
  end

  def close(socket) do
    :gen_tcp.close(socket)
  end

  defp parse(ip) do
    :inet.parse_address(~c"#{ip}") |> elem(1)
  end
end

defmodule Modbus do
  alias Modbus.Transport
  alias Modbus.Protocol

  @toms 4000

  def open(opts) do
    transm = Keyword.get(opts, :trans, Modbus.Tcp.Transport)
    protom = Keyword.get(opts, :proto, Modbus.Tcp.Protocol)
    tid = Protocol.next(protom, nil)

    case Transport.open(transm, opts) do
      {:ok, transi} ->
        transp = {transm, transi}
        {:ok, %{trans: transp, proto: protom, tid: tid}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def close(%{trans: trans}), do: Transport.close(trans)

  def exec(conn, cmd, opts \\ []) when is_tuple(cmd) do
    %{trans: trans, proto: proto, tid: tid} = conn
    timeout = Keyword.get(opts, :timeout, @toms)
    tracer = Keyword.get(opts, :tracer, fn _, _ -> :ok end)
    conn = Map.put(conn, :tid, Protocol.next(proto, tid))

    with {:ok, request, length} <- request(proto, cmd, tid),
         :ok <- tracer.(:output, request),
         :ok <- Transport.write(trans, request),
         {:ok, resp} <- Transport.readn(trans, length, timeout),
         :ok <- tracer.(:input, resp) do
      case parse(proto, cmd, resp, tid) do
        {:error, error} -> {:error, conn, error}
        nil -> {:ok, conn}
        values -> {:ok, conn, values}
      end
    else
      {:error, error} ->
        {:error, conn, error}
    end
  end

  defp request(proto, cmd, tid) do
    try do
      request = Protocol.pack_req(proto, cmd, tid)
      length = Protocol.res_len(proto, cmd)
      {:ok, request, length}
    rescue
      _ ->
        {:error, {:request, cmd: cmd, tid: tid}}
    end
  end

  defp parse(proto, cmd, resp, tid) do
    try do
      Protocol.parse_res(proto, cmd, resp, tid)
    rescue
      _ -> {:error, {:parse, cmd: cmd, tid: tid, resp: resp}}
    end
  end

  # for testing
  def tid(conn), do: Map.get(conn, :tid)
  def tid(conn, tid), do: Map.put(conn, :tid, tid)
end

:ok
