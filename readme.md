# Yeico Flex

```bash
terminal dev flex.exs

# open your browser at http://localhost:4080/

# https://github.com/samuelventura/modbus

# opto22 learning center configured with script/opto22.otg
# the otg is for an R2 but seems to work for R1, EB1, and EB2
# digital points increment address by 4 per module and by 1 per point
# analog points increment address by 8 per module and by 2 per point

# 1:0:RDI:NONE Emergency,POS,FreezerDoor,PhotoSensor
# 1:4:WDO:NONE Alarm,FreezerDoorStatus,InsideLight,OutsideLight
# 1:16:WRO:F32BE FuelDisplay,AOutput1
# 1:32:RRI:F32BE FuelLevel,AInput1

s=1,a=7,c=fc,d=1 # Opto22 LC - Turn On Outside Light
s=1,a=7,c=fc,d=0 # Opto22 LC - Turn Off Outside Light
s=1,a=7,c=rc,d=1 # Opto22 LC - Read Outside Light as Coil
s=1,a=7,c=ri,d=1 # Opto22 LC - Read Outside Light as Input

s=1,a=6,c=fc,d=1 # Opto22 LC - Turn On Inside Light
s=1,a=6,c=fc,d=0 # Opto22 LC - Turn Off Inside Light
s=1,a=6,c=rc,d=1 # Opto22 LC - Read Inside Light as Coil
s=1,a=6,c=ri,d=1 # Opto22 LC - Read Inside Light as Input

s=1,a=5,c=fc,d=1 # Opto22 LC - Turn On Freezer Door Status
s=1,a=5,c=fc,d=0 # Opto22 LC - Turn Off Freezer Door Status
s=1,a=5,c=rc,d=1 # Opto22 LC - Read Freezer Door Status as Coil
s=1,a=5,c=ri,d=1 # Opto22 LC - Read Freezer Door Status as Input

s=1,a=4,c=fc,d=1 # Opto22 LC - Turn On Alarm
s=1,a=4,c=fc,d=0 # Opto22 LC - Turn Off Alarm
s=1,a=4,c=rc,d=1 # Opto22 LC - Read Alarm as Coil
s=1,a=4,c=ri,d=1 # Opto22 LC - Read Alarm as Input

s=1,a=4,c=fc,d=1111 # Opto22 LC - Turn On All Digital Outputs
s=1,a=4,c=fc,d=0000 # Opto22 LC - Turn Off All Digital Outputs
s=1,a=4,c=fc,d=1010 # Opto22 LC - Turn Off All Digital Outputs
s=1,a=4,c=fc,d=0101 # Opto22 LC - Turn Off All Digital Outputs
s=1,a=4,c=rc,d=4 # Opto22 LC - Read All Digital Outputs as Coils
s=1,a=4,c=ri,d=4 # Opto22 LC - Read All Digital Outputs as Inputs

s=1,a=0,c=rc,d=1 # Opto22 LC - Read Emergency as Coil
s=1,a=0,c=ri,d=1 # Opto22 LC - Read Emergency as Input

s=1,a=1,c=rc,d=1 # Opto22 LC - Read POS as Coil
s=1,a=1,c=ri,d=1 # Opto22 LC - Read POS as Input

s=1,a=2,c=rc,d=1 # Opto22 LC - Read Freezer Door as Coil
s=1,a=2,c=ri,d=1 # Opto22 LC - Read Freezer Door as Input

s=1,a=3,c=rc,d=1 # Opto22 LC - Read Photo Sensor as Coil
s=1,a=3,c=ri,d=1 # Opto22 LC - Read Photo Sensor as Input

s=1,a=0,c=rc,d=4 # Opto22 LC - Read All Digital Inputs as Coils
s=1,a=0,c=ri,d=4 # Opto22 LC - Read All Digital Inputs as Inputs

s=1,a=16,c=phr,d=2.5,e=f32be # Opto22 LC - Write Fuel Display
s=1,a=16,c=phr,d=5.8,e=f32be # Opto22 LC - Write Fuel Display
s=1,a=16,c=rir,d=1,e=f32be # Opto22 LC - Read Fuel Display as Input Register
s=1,a=16,c=rhr,d=1,e=f32be # Opto22 LC - Read Fuel Display as Output Register

s=1,a=24,c=rir,d=1,e=f32be # Opto22 LC - Read Store Temperature as Input Register
s=1,a=24,c=rhr,d=1,e=f32be # Opto22 LC - Read Store Temperature as Output Register

s=1,a=32,c=rir,d=1,e=f32be # Opto22 LC - Read Fuel Level as Input Register
s=1,a=32,c=rhr,d=1,e=f32be # Opto22 LC - Read Fuel Level as Output Register

# spare channels
s=1,a=18,c=wro,d=3.4,e=f32be # Opto22 LC - Write to AOV27 ch2
s=1,a=18,c=wro,d=4.3,e=f32be # Opto22 LC - Write to AOV27 ch2
s=1,a=34,c=rri,d=1,e=f32be # Opto22 LC - Read from AIV ch2

# Turck vibration and temp sensor CMVT-QR20-IOLX3-H1141
# https://www.turck.com.mx/datasheet/_en/edb_100016543_gbr_en.pdf
s=1,a=49,c=rri,d=1,e=u16le # Turck - Read Temp
s=1,a=50,c=rri,d=1,e=u16le # Turck - Read Magnitud
s=1,a=51,c=rri,d=1,e=u16le # Turck - Read Z
s=1,a=52,c=rri,d=1,e=u16le # Turck - Read Y
s=1,a=53,c=rri,d=1,e=u16le # Turck - Read Z
s=1,a=49,c=rri,d=5,e=u16le # Turck - Read All

# Modbus Devices
# TCP,192.168.1.5:502,disabled,Turck
# 1:49:RRI:U16LE Temp,Sum,Z,Y,X

# Laurel 9600,Append CR,Packet CR
# https://www.laurels.com/downloadfiles/serialcom.pdf
# continuous mode *1A0<cr>[<nl>]
# command mode *1A1<cr>[<nl>]
# read command *1B0<cr>[<nl>]
```

## Reference

- https://browserpad.org/
- https://tailscan.com/colors
- Styles
```css
# label
color: white;
font-size: 16px;
text-align: left;
padding: 0px 0px;
background-color: transparent;
# button
color: white;
font-size: 16px;
padding: 2px 16px;
border-radius: 4px;
text-align: center;
background-color: blue;
disabled:background-color: gray;
active:background-color: orange;
hover:background-color: green;
```
- Calculator
```elixir
disabled = values == default
text = f.("Button ~s", default)
```

## Fixme

- [ ] Document live view life cycle
- [ ] Make flex pages password protected: use put cookie as regular login
- [ ] Shaky things: browser, mountrap, socat, kill links, unable to await defers, modbus lib
- [ ] Modbus lib deterministic error detection
- [ ] Modbus rtu over tcp packet fragmentation
- [ ] Clone controls to easy copy template styling
- [ ] Prevent read/write to points with empty names
- [ ] Show io_lib format escapes help in props editor
- [ ] CubDB screen design db cleanup strategy
- [ ] Define mqtt strategy
- [ ] Implement links between user screens
- [ ] Screen designer stumped after several enable/disable
- [ ] Task to periodically delete unreferenced screen designs
- [ ] Inplace testing with a global enable flag (see lib-convert)
- [ ] f32le untested, is endianess applied at register or byte level?
- [-] Split screen viewer from screen runner (listener and calculations)
  - No appreciable gain for the moment (until some common calculation is required)
  - The approach of calculation the runtime part and broadcasting that look heavier the current approach
  - Centralized optimization requires incremental broadcasts 
- [ ] Per modbus device status source point (int - string type)
- [ ] Unable to convert float string to int while adding a button on Linux
  - different pointer coordinate type by platform?
- Terminal dying on save hot reload: 
  - ** (MatchError) no match of right hand side value: [{#PID<0.1105.0>, nil}] Unexpected exit: 256
  - Applet.Unique   {{:applet_super, "flex.exs"}, #PID<0.1105.0>, nil},
- [x] Why html text has such a large y padding?: leading-none
- [x] Button hover and press visual feedback: with parametric pseudo classes hover and active
- [?] Panel drag gets in the way of reliable clicks: drag requires shift pressed now (enough?)
- [?] Label parametric text (and parametric style?): only parametric text and parametric pseudo classes (enough?)
- [x] How to style button hover using just the style attribute: embedded style tags for each supported pseudo class
- [x] Define panel design and runtime style defaults: text-white, text-base, [&_*]:cursor-default, leading-none
- [x] How to draw border inside bounds to avoid resize on select
  - use outline instead
- [x] Styling globals: bg-black select-none text-base cursor-default
  - cursor-default to remove safari text cursor (managed externally)
  - [&_*]:cursor-default required for button and anchor
  - [&_*]:text-xs required for form inputs
- [x] z-order checks
  - top-left global menu get on top of screen designer
  - hero icons in modbus points editor are visible
  - modals get on top of everything
- [x] Why clicks are coming from design_port and not from design_panel?: masked by port pointerdown listener
- [x] Standardize serial-exports/modbus-devices/user-screens to generic-items lib/loop/view template
- [x] Menu gets under screen design absolute positioned and transformed panel: explicit flex components z-index
- [x] Socket terminal split hex and printable view
- [x] Modbus log input/output as full hex: [00]![00000006010200030001]
- [x] Modbus devices viewer slowed down to the point of modal delayed actions
  - Same impact expected to logic engine? <- this may be the real engineering challenge
  - Move from event driven to polling
  - Implement per device delay
  - Comment out view logging
- [x] Make enter-navigation work on dynamic points editor
- [-] Test multi connections to socat serial listener: second connection rejected
- [x] Modbus terminal parse dhb values
- [x] Modbus float formatting: F for float_be and f for float_le
- [x] Modbus enforce data and count ranges
- [x] Loop logs type should be just error? true|false
- [x] Avoid serial loop run delay by explicit pid killing on restart
- [x] Hero icons with z-index -1 wont show on modal: add z-0
- [x] Hero icons show on top of menu: z-index: -1 on tailwind config
- [x] Disabled selects show on top of menu: opacity: 1
- [x] Disabled selects darker than inputs: opacity: 1
- [x] Ugly focused button ring: outline-none
- [x] Select and button text too dim
- [x] Form elements look too big: check padding
- [-] Use tailwind disabled: marker (link requires conditional)
- [x] Standardize form styling: disabled > focus > hover > normal
- [x] Enter navigates forms until submit button
- [x] Form fields get reset if page updates while open: use phx-update="ignore"
- [-] No serial number in some serial by id path 
  - Amazon ttl uart /dev/serial/by-id/usb-Prolific_Technology_Inc._USB-Serial_Controller_D-if00-port0
  - Laurels has serial number /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AK05WHP2-if00-port0
- [x] Socat creates tty if not found, and it wont open it until there is a tcp client connection, it may be removed mean while
- [x] IP pattern from https://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp
- [x] Scrolling overflow-y-auto in nested flex requires:
  - h-full parent and overflow-hidden grand parent and h-screen on flex root.
- [x] Using [0102] instead of \x0102 allows to differenciate bitween [01]a and \x01a
- [x] Printable groups control chars
- [ ] Terminal bug?
```
close: {{:badfun, nil}, [{Applet.Api, :call, 1, [file: ~c"lib/applet/api.ex", line: 251]}, {TerminalWeb.HomeLive, :"-wrap/1-fun-1-", 2, [file: ~c"include/home.exs", line: 176]}, {TerminalWeb.HomeLive, :apply, 4, [file: ~c"include/home.exs", line: 161]}, {TerminalWeb.HomeLive, :handle_event, 3, [file: ~c"include/home.exs", line: 120]}, {Phoenix.LiveView.Channel, :"-view_handle_event/3-fun-0-", 3, [file: ~c"lib/phoenix_live_view/channel.ex", line: 509]}, {:telemetry, :span, 3, [file: ~c"/Users/samuel/Library/Caches/mix/installs/ex-1.19.1-erl-16.1.1/G3ornCiKhOG3d40YuqxB7A/deps/telemetry/src/telemetry.erl", line: 359]}, {Phoenix.LiveView.Channel, :handle_info, 2, [file: ~c"lib/phoenix_live_view/channel.ex", line: 260]}, {:gen_server, :try_handle_info, 3, [file: ~c"gen_server.erl", line: 2434]}]}]
```