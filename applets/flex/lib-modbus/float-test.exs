use Terminal

[+0.0] = float.from_be_abcd.([0, 0])
[+0.0] = float.from_le_cdab.([0, 0])
[+0.0] = float.from_le_dcba.([0, 0])
[0, 0] = float.to_be_abcd.([0.0])
[0, 0] = float.to_le_cdab.([0.0])
[0, 0] = float.to_le_dcba.([0.0])

[0x4059, 0x999A] = float.to_be_abcd.([3.4])
[0x999A, 0x4059] = float.to_le_cdab.([3.4])
[0x9A99, 0x5940] = float.to_le_dcba.([3.4])

[3.4000000953674316] = float.from_be_abcd.([0x4059, 0x999A])
[3.4000000953674316] = float.from_le_cdab.([0x999A, 0x4059])
[3.4000000953674316] = float.from_le_dcba.([0x9A99, 0x5940])

:ok
