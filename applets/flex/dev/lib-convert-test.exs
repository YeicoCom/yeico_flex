use Terminal

true = 0.0 == +0.0
true = 0.0 == -0.0

{:ok, +0.0} = libConvert.toFloat.("+0")
{:ok, -0.0} = libConvert.toFloat.("-0")

{:ok, +0.0} = libConvert.toFloat.("0")
{:ok, +0.0} = libConvert.toFloat.("0.0")

{:ok, +0.0} = libConvert.toFloat.(0)
{:ok, +0.0} = libConvert.toFloat.(0.0)

{:error, "Invalid float format: 0.0x [302E3078]"} = libConvert.toFloat.("0.0x")
{:error, "Invalid float format: x [78]"} = libConvert.toFloat.("x")
{:error, "Invalid float convert: :x"} = libConvert.toFloat.(:x)

{:ok, 0} = libConvert.toInteger.(0)
{:ok, 0} = libConvert.toInteger.("0")

{:error, "Invalid integer format: 0x [3078]"} = libConvert.toInteger.("0x")
{:error, "Invalid integer format: x [78]"} = libConvert.toInteger.("x")
{:error, "Invalid integer convert: :x"} = libConvert.toInteger.(:x)
{:error, "Invalid integer convert: 0.0"} = libConvert.toInteger.(0.0)

:ok
