use Terminal

short = "s=Slave,a=Address,c=[rdi,rdo,wdo,rri,rro,wro],d=Data,e=[f32be,f32le,u16be,u16le]#Comment"

full = """
Values are decimal by default and can be prefixed with:
  h for hexadecimal
  d for decimal
  b for binary

s: Slave [0-255] or [h00-hFF]
a: Address [0-65535] or [h0000-hFFFF]
c: Code
  rdi to read digital input(s)
  rdo to read digital output(s)
  wdo to write digital output(s)
  rri to read register input(s)
  rro to read register output(s)
  wro to write register output(s)
  ri to read input point(s)
  rc to read discrete coil(s)
  fc to force discrete coil(s)
  rir to read input register(s)
  rhr to read holding register(s)
  phr to preset holding register(s)
d: Read count
  or binary encoded digital data to output
  or colon separated register data to output
e: Encoding
  f32be 32 bit big endian IEEE754 float encoding
  f32le 32 bit little endian IEEE754 float encoding
  u16be 16 bit big endian unsigned integer
  u16le 16 bit little endian unsigned integer
#: Name or comment
"""

:ok
