use Flex

Flex.eval_file("help.exs", [])
Flex.eval_file("parser.exs", [])
Flex.eval_file("modbus.exs", [])
Flex.eval_file("convert.exs", [])
Flex.eval_file("encoder.exs", [])
Flex.eval_file("slave.exs", [])
Flex.eval_file("command.exs", [])

Flex.eval_test("modbus-test.exs", [])
Flex.eval_test("convert-test.exs", [])
Flex.eval_test("command-test.exs", [])

defmodule Flex.Mb do
  def master_open(opts), do: Modbus.open(opts)
  def master_close(conn), do: Modbus.close(conn)
  def master_exec(conn, cmd, opts \\ []), do: Modbus.exec(conn, cmd, opts)
  def slave_apply(proto, key, data), do: Modbus.Slave.apply(proto, key, data)
  def get_encoder(encoding), do: Modbus.Encoder.for(encoding)
  def get_proto("TCP"), do: Modbus.Tcp.Protocol
  def get_proto("RTU"), do: Modbus.Rtu.Protocol
  def safe_parse(cmdline), do: Modbus.Command.safe_parse(cmdline)
  def help_short, do: Modbus.Help.short()
  def help_full, do: Modbus.Help.full()
end

:ok
