use Terminal

help = flex.evalScript.("help.exs", [])
parser = flex.evalScript.("parser.exs", [])
modbus = flex.evalScript.("modbus.exs", toms: 4_000)
master = flex.evalScript.("master.exs", modbus: modbus, toms: 4_000)
convert = flex.evalScript.("convert.exs", [])
encoder = flex.evalScript.("encoder.exs", convert: convert, parser: parser)
command = flex.evalScript.("command.exs", parser: parser, encoder: encoder)
slave = flex.evalScript.("slave.exs", master: master)

flex.evalTest.("modbus-test.exs", modbus: modbus, slave: slave)
flex.evalTest.("convert-test.exs", convert: convert)
flex.evalTest.("command-test.exs", command: command)

# FIXME: cache encoder in modbus devices loop
# most performance critical to the top
api = fn
  :master, exec: args -> master.exec.(args)
  :master, open: opts -> master.open.(opts)
  :master, close: conn -> master.close.(conn)
  :encoder, get: encoding -> encoder.get.(encoding)
  :slave, proto: proto, key: key -> slave.build.(proto, key)
  :proto, get: "TCP" -> modbus.tcp_proto
  :proto, get: "RTU" -> modbus.rtu_proto
  :parse, cmdline: cmdline -> command.parse.(cmdline)
  :help, :short -> help.short
  :help, :full -> help.full
  key, opts -> Api.warn(key: key, opts: opts)
end

:ok
