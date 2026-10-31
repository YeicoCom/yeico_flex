# nanob with dtoverlay=uart2
# /dev/ttyAMA2 GPIO0/27-TX GPIO1-RX/28
use Terminal

Flex.SerialExport.new()
|> Flex.SerialExport.set(tty: "/dev/ttyAMA2")
|> Flex.SerialExport.set(bauds: 57600)
|> Flex.SerialExport.set(port: 4041)
|> Flex.SerialExport.run(rdms: 1000, name: "r307_tty")

Flex.SensorR307.new()
|> Flex.SensorR307.set(ip: "127.0.0.1")
|> Flex.SensorR307.set(port: 4041)
|> Flex.SensorR307.run(rdms: 1000, name: "r307_sensor", deps: ["r307_tty"])

:ok
