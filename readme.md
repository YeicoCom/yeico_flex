# Yeico Flex

```bash
terminal dev flex.exs

# open your browser at http://localhost:4080/
```

## Fixme

- [ ] Socket terminal modes
  - Laurel https://www.laurels.com/downloadfiles/serialcom.pdf
  - Laurel continuous mode *1A0<cr>[<nl>]
  - Laurel command mode *1A1<cr>[<nl>]
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
