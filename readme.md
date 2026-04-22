# Yeico Flex

```bash
terminal dev flex.exs

# open your browser at http://localhost:4080/

# https://github.com/samuelventura/modbus

# opto22 learning center configured with script/opto22.otg
# the otg is for an R2 but seems to work for R1, EB1, and EB2
# digital points increment address by 4 per module and by 1 per point
# analog points increment address by 8 per module and by 2 per point

# Emergency,POS,FreezerDoor,PhotoSensor
# Alarm,FreezerDoorStatus,InsideLight,OutsideLight

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

# FIXME
s=1,a=16,c=phr,d=1:2 # Opto22 LC - Write Fuel Display
s=1,a=16,c=rir,d=2 # Opto22 LC - Read Fuel Display

s=1,a=24,c=rir,d=2 # Opto22 LC - Read Store Temperature as Input Register
s=1,a=24,c=rhr,d=2 # Opto22 LC - Read Store Temperature as Output Register

s=1,a=32,c=rir,d=2 # Opto22 LC - Read Fuel Level as Input Register
s=1,a=32,c=rhr,d=2 # Opto22 LC - Read Fuel Level as Output Register
```

## Fixme

- [ ] Socket terminal modes
  - Laurel https://www.laurels.com/downloadfiles/serialcom.pdf
  - Laurel continuous mode *1A0<cr>[<nl>]
  - Laurel command mode *1A1<cr>[<nl>]
- [ ] Modbus log input/output as full hex: [00]![00000006010200030001]
- [ ] Make enter-navigation work on dynamic points editor
- [ ] Test multi connections to socat serial listener
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
- [x] Scrolling in nested flex requires h-full parent and overflow-hidden grand parent and h-screen on flex root.
- [x] Using [0102] instead of \x0102 allows to differenciate bitween [01]a and \x01a
- [x] Printable groups control chars
