use Terminal

help = Adb.get("flex:api").evalScript.("help.exs", [])
float = Adb.get("flex:api").evalScript.("float.exs", [])
parser = Adb.get("flex:api").evalScript.("parser.exs", [])
master = Adb.get("flex:api").evalScript.("master.exs", [])
encoder = Adb.get("flex:api").evalScript.("encoder.exs", float: float, parser: parser)
command = Adb.get("flex:api").evalScript.("command.exs", parser: parser, encoder: encoder)

Adb.get("flex:api").evalTest.("float-test.exs", float: float)
Adb.get("flex:api").evalTest.("command-test.exs", command: command)

api = fn
  :parse, proto: "TCP" -> master.tcp_proto
  :parse, proto: "RTU" -> master.rtu_proto
  :master, open: opts -> master.open.(opts)
  :master, exec: args -> master.exec.(args)
  :parse, cmdline: cmdline -> command.parse.(cmdline)
  :encoder, encoding: encoding -> encoder.encoder.(encoding)
  :help, :short -> help.short
  :help, :full -> help.full
end

:ok
