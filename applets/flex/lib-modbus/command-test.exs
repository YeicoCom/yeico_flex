use Terminal

test = fn cmd, line ->
  {:ok, %{cmd: ^cmd, get: _}} = command.parse.(line)
end

# digital command sweep
test.({:ri, 1, 2, 3}, "s=1,a=2,c=rdi,d=3")
test.({:rc, 1, 2, 3}, "s=1,a=2,c=rdo,d=3")
test.({:fc, 1, 2, [1]}, "s=1,a=2,c=wdo,d=1")
test.({:fc, 1, 2, [1, 1]}, "s=1,a=2,c=wdo,d=11")

# register command sweep
test.({:rir, 1, 2, 3}, "s=1,a=2,c=rri,d=3")
test.({:rhr, 1, 2, 3}, "s=1,a=2,c=rro,d=3")
test.({:phr, 1, 2, [3]}, "s=1,a=2,c=wro,d=3")
test.({:phr, 1, 2, [3, 4]}, "s=1,a=2,c=wro,d=3:4")

# digital data sweep
test.({:fc, 1, 2, [0, 1]}, "s=1,a=2,c=wdo,d=01")

# register data sweep
test.({:phr, 1, 2, [0, 65535]}, "s=1,a=2,c=wro,d=0:65535")
test.({:phr, 1, 2, [0, 1]}, "s=1,a=2,c=wro,d=b0:b1")
test.({:phr, 1, 2, [0, 65535]}, "s=1,a=2,c=wro,d=d0:d65535")
test.({:phr, 1, 2, [0, 65535]}, "s=1,a=2,c=wro,d=h0:hffff")

# digital count data sweep
test.({:ri, 1, 2, 1}, "s=1,a=2,c=rdi,d=1")
test.({:ri, 1, 2, 1}, "s=1,a=2,c=rdi,d=b1")
test.({:ri, 1, 2, 1}, "s=1,a=2,c=rdi,d=d1")
test.({:ri, 1, 2, 1}, "s=1,a=2,c=rdi,d=h1")
test.({:ri, 1, 2, 2040}, "s=1,a=2,c=rdi,d=2040")
test.({:ri, 1, 2, 2040}, "s=1,a=2,c=rdi,d=d2040")
test.({:ri, 1, 2, 2040}, "s=1,a=2,c=rdi,d=h7f8")

# register count data sweep
test.({:rir, 1, 2, 1}, "s=1,a=2,c=rri,d=1")
test.({:rir, 1, 2, 1}, "s=1,a=2,c=rri,d=b1")
test.({:rir, 1, 2, 1}, "s=1,a=2,c=rri,d=d1")
test.({:rir, 1, 2, 1}, "s=1,a=2,c=rri,d=h1")
test.({:rir, 1, 2, 127}, "s=1,a=2,c=rri,d=127")
test.({:rir, 1, 2, 127}, "s=1,a=2,c=rri,d=d127")
test.({:rir, 1, 2, 127}, "s=1,a=2,c=rri,d=h7f")

# slave sweep
test.({:ri, 0, 2, 3}, "s=0,a=2,c=rdi,d=3")
test.({:ri, 0, 2, 3}, "s=b0,a=2,c=rdi,d=3")
test.({:ri, 0, 2, 3}, "s=d0,a=2,c=rdi,d=3")
test.({:ri, 0, 2, 3}, "s=h0,a=2,c=rdi,d=3")
test.({:ri, 255, 2, 3}, "s=255,a=2,c=rdi,d=3")
test.({:ri, 255, 2, 3}, "s=d255,a=2,c=rdi,d=3")
test.({:ri, 255, 2, 3}, "s=hff,a=2,c=rdi,d=3")

# address sweep
test.({:ri, 1, 0, 3}, "s=1,a=0,c=rdi,d=3")
test.({:ri, 1, 0, 3}, "s=1,a=b0,c=rdi,d=3")
test.({:ri, 1, 0, 3}, "s=1,a=d0,c=rdi,d=3")
test.({:ri, 1, 0, 3}, "s=1,a=h0,c=rdi,d=3")
test.({:ri, 1, 255, 3}, "s=1,a=255,c=rdi,d=3")
test.({:ri, 1, 255, 3}, "s=1,a=d255,c=rdi,d=3")
test.({:ri, 1, 255, 3}, "s=1,a=hff,c=rdi,d=3")

# encoding sweep
test.({:rir, 1, 0, 3}, "s=1,a=0,c=rri,d=3,e=NONE")
test.({:rir, 1, 0, 6}, "s=1,a=0,c=rri,d=3,e=f32be")
test.({:rir, 1, 0, 6}, "s=1,a=0,c=rri,d=3,e=f32le")
test.({:rir, 1, 0, 3}, "s=1,a=0,c=rri,d=3,e=u16be")
test.({:rir, 1, 0, 3}, "s=1,a=0,c=rri,d=3,e=u16le")

test.({:phr, 1, 0, [3]}, "s=1,a=0,c=wro,d=3,e=NONE")
test.({:phr, 1, 0, [0x0003]}, "s=1,a=0,c=wro,d=3,e=u16be")
test.({:phr, 1, 0, [0x0300]}, "s=1,a=0,c=wro,d=3,e=u16le")
test.({:phr, 1, 0, [0xFFFD]}, "s=1,a=0,c=wro,d=-3,e=s16be")
test.({:phr, 1, 0, [0xFDFF]}, "s=1,a=0,c=wro,d=-3,e=s16le")
test.({:phr, 1, 0, [0x4059, 0x999A]}, "s=1,a=0,c=wro,d=3.4,e=f32be")
test.({:phr, 1, 0, [0x999A, 0x4059]}, "s=1,a=0,c=wro,d=3.4,e=f32le")

:ok
