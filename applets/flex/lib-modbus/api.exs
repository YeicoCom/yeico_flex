use Terminal

help = Adb.get("flex:api").evalScript.("help.exs", [])
parser = Adb.get("flex:api").evalScript.("parser.exs", [])
modbus = Adb.get("flex:api").evalScript.("modbus.exs", toms: 4_000)
master = Adb.get("flex:api").evalScript.("master.exs", modbus: modbus, toms: 4_000)
convert = Adb.get("flex:api").evalScript.("convert.exs", [])
encoder = Adb.get("flex:api").evalScript.("encoder.exs", convert: convert, parser: parser)
command = Adb.get("flex:api").evalScript.("command.exs", parser: parser, encoder: encoder)
slave = Adb.get("flex:api").evalScript.("slave.exs", master: master)

Adb.get("flex:api").evalTest.("modbus-test.exs", modbus: modbus, slave: slave)
Adb.get("flex:api").evalTest.("convert-test.exs", convert: convert)
Adb.get("flex:api").evalTest.("command-test.exs", command: command)

# FIXME: cache encoder in modbus devices loop
# most performance critical to the top
api = fn
  :encoder, get: encoding -> encoder.get.(encoding)
  :master, exec: args -> master.exec.(args)
  :master, open: opts -> master.open.(opts)
  :master, close: conn -> master.close.(conn)
  :slave, proto: proto, key: key -> slave.build.(proto, key)
  :proto, get: "TCP" -> modbus.tcp_proto
  :proto, get: "RTU" -> modbus.rtu_proto
  :parse, cmdline: cmdline -> command.parse.(cmdline)
  :help, :short -> help.short
  :help, :full -> help.full
  key, opts -> Api.warn(key: key, opts: opts)
end

:ok
