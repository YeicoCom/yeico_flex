# Flex Versions

## flex

An applet to be loaded into newly commissioned terminals for connecting and interacting with modbus and serial devices with d&d UI designer. I guess the intuition was to provide the end user with a set of ready to configure and use tools.

## flex2

A client side scriptable environment with visual editor and logger to run both scripts and backends with server side filesystem based repo. I guess the intuition was to provide the end user with a integrated ide. Never really used so far. Entity runner is a central idea but not really tested and trusted. The nestedness feels dangerous and repetitive.

## flex3a

A set of tools packaged as an standard elixir package to be included in a compiled applet app. Neither of the previous version allows to easily launch a serial port export from another applet. The flex2 entity runner is a great idea, test and refine it. Redesign it to be run directly in applets with standard applet logs and context. No sure how to develop an standard elixir app that depends on the applet/terminal environment.

## flex3b

- Logic and view reactors with a fluid builder api for fast text based data flow programming.
- Elixir reliabilty with a Python scripting feel.
- Seamless edge to cloud with standard tooling.
- Scriptable OTP best practices.
