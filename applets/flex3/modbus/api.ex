defmodule Flex3.Modbus do
  def master_open(opts), do: Modbus.Master.open(opts)
  def master_close(conn), do: Modbus.Master.close(conn)
  def master_exec(conn, cmd, opts \\ []), do: Modbus.Master.exec(conn, cmd, opts)
  def slave_apply(proto, key, data), do: Modbus.Slave.apply(proto, key, data)
  def get_encoder(encoding), do: Modbus.Encoder.for(encoding)
  def get_proto("TCP"), do: Modbus.Tcp.Protocol
  def get_proto("RTU"), do: Modbus.Rtu.Protocol
  def safe_parse(cmdline), do: Modbus.Command.safe_parse(cmdline)
  def help_short, do: Modbus.Help.short()
  def help_full, do: Modbus.Help.full()
end
