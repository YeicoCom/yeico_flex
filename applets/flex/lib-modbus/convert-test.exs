use Terminal

0x8000 = convert.from.(:u16be, 32768)
0x0080 = convert.from.(:u16le, 32768)
0x8000 = convert.from.(:s16be, -32768)
0x0080 = convert.from.(:s16le, -32768)
[0x4059, 0x999A] = convert.from.(:f32be, 3.4)
[0x999A, 0x4059] = convert.from.(:f32le, 3.4)

32768 = convert.to.(:u16be, 0x8000)
32768 = convert.to.(:u16le, 0x0080)
-32768 = convert.to.(:s16be, 0x8000)
-32768 = convert.to.(:s16le, 0x0080)
3.4000000953674316 = convert.to.(:f32be, [0x4059, 0x999A])
3.4000000953674316 = convert.to.(:f32le, [0x999A, 0x4059])

# what opto22 returns for empty analog points
-3.4028235e38 = convert.to.(:f32be, [0xFFFF, 0xFFFF])
-3.4028235e38 = convert.to.(:f32le, [0xFFFF, 0xFFFF])

:ok
