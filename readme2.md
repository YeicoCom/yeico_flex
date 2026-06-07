# Vision

- Script+backend+view architecture
- Fully capable web code editor
- Concurrent editing capabilities
- Online entity repository

# Flow

- FS > Repo
- Repo > Daemon > runner > log > Buffer > View > Web
- Repo > Buffer > View > Web
- Web > View > FS
- Repo > Daemon is the critical one
- All other just cause logs loss or leakage at the web ui

# Super

- Support Services
  - Echo servers
  - Modbus slaves
  - Socat fake ttys
  - Serial exports
  - Points map
- Main Services
  - Repo
  - Daemon
  - Buffer
- Scripts
- Script Children

# Log

- Entity.run: unsafe call to Runner.run for code defined entities (let exceptions show in calling log view)
- Daemon.run: unsafe call to Runner.run (errors here are considered bugs to be tracked and fixed)
- Runner.call: safe call to each entity callback: clean, start
- ReactiveLogic: on each fun execution
- LiveScreen: on each fun execution

# Fixme

- [ ] Email login (with fixed email list)
- [ ] CLI tool to rsync and view logs
- [ ] Screen browser and viewer
- [ ] UI widgets with custom JS

- [ ] Modbus master entity
- [ ] Modbus slave entity
- [ ] File upload browser
- [ ] Modbus terminal view
- [ ] Socket terminal view
- [ ] Modbus devices viewer

- [ ] Secure terminal_cookie
- [ ] Implement terminal login
- [ ] Document terminal security: salts, cookies, secrets, slave shell/bindings, etc..
- [-] Terminal cloud home folder contains run and tmp: same across fw, dev, and serve

- [ ] log: make script/backend logs show up on web ide and terminal dev console
- [ ] log: make script/backend children logs show up on web ide and terminal dev console
- [ ] log: ensure exceptions shows module and fun number
- [ ] log: capture all script stdio
- [ ] implement screen browser and embedded viewer
- [ ] applet: runner supervisor to register a timestamp for Flex2.Print.tasks
- [ ] applet: all applets must restart if a dep is restarted (mdb, udb, ...)
    -  terminal restarts if applet app does? 
    -  mmm... terminal and applet app supers are one_for_one!
- [ ] Flex2.Live.view to register and broadcast path

- [ ] ensure correctness of buffered logs
    - may lose at start or end of execution
    - maybe repo should sync call buffer/daemon in reverse order for add/delete
    - maybe buffer should store anything it gets and defer garbage collection of dead pids
- [ ] Log using groupleader for finer filtering?
    - if each script/backend is a groupleader
    - each child entity logs to stdout 
    - each child entity ansi escapes by level
    - each child entity must self identify in the log msg
    - children unhandled exceptions require stacktrace for id purposes
    - how to handle timestamp localization?

- [ ] what is runner name being used for?
    - observable map has adb?
- [ ] Scrollbars with diverse styling chrome/safari

- [ ] addEdgeGroup not honoring initialSize
- [ ] Dockview how to persist only edge groups size?
- [ ] Backend left group header renders add icon out of sigth on load
    - check demo src https://dockview.dev/demo/?theme=abyss
    - only happens when there is a file listed
- [ ] Flicker on non active editor close (file selection moves too fast)
- [ ] Screen funs not shown on macos sleep woke up (nil size?)
- [ ] Each entity registers a print method to dump its index
- [ ] Entity stage and error
    - entity:stage:ID nil,0,1 handled by the runner
    - entity:error:ID string fully handled by the entity
    - no really relevant?
- [ ] Drop dockview: custom svelte?

- [x] 10px font too small for linux, berely manageable for macos: moved to 12px.
- [x] Slogan: Kernel pid terminated (application_controller) ("{application_start_failure,kernel,{{shutdown,{failed_to_start_child,net_sup,{shutdown,{failed_to_start_child,net_kernel,{'EXIT',nodistribution}}}}},{kernel,start,[normal,[]]}}}")
    - No error gets reported on the web console
    - pong wait was blocking the stdio loop
- [-] autoscroll goes to top instead of bottom on non active panel/log-viewer
    - autoscroll off DOM calculation fail
- [x] Clean before start on first run: kinda non reentrant as well
- [-] Move to supervisor for repo/buffer/super? nope
- [-] Erlang app/module automatic module loading and unloading?
    - nope, stopping an app does not unload every module
    - https://www.erlang.org/doc/system/release_handling.html
- [x] Integrate the log viewer to the right of the code editor itself: with split.js
- [x] use daemon clean to wait for all runner defers to complete
- [-] entity get a different id assigned on each run: intrinsic nature
- [-] make clean calls non re-entrant: kinda with kill(id)
- [x] no output from script nested entity runner
- [x] Runners clean not being called on applet stop: solved by killable defer
- [-] Backend tmp and permanent storage. 
    - tmp yes, permanent nope, it would mean clean need to leaving things behind
- [x] implement backend runner
- [x] applet: loop to sleep only remaing rdms (did the same for runners loop)
- [x] applet: async(fun0, opts) and async(fun1, arg, opts)
- [x] applet: loop(fun0, opts) and loop(fun1, arg, opts)
- [x] backend mix install funny broken latin1 macos output 
    - not really latin1 but utf8 (noticed box building chars on compile exception report)
- [-] support ansi escapes in web log viewer: not really needed after all
- [x] Defer based supervisor: yes! kinda.
- [x] current daemon kill on file delete wont call runner clean
    - now it does by calling Runner.kill(context) instead of direct task kill
- [-] Extensible validation
    - Already supports passing a function
- [x] Browser panel wont scroll
- [x] Editor are not being removed on reconnected/updated-nil
- [-] Dockview flicker on document load
    - Timer to remove hidden class on load
- [-] Phoenix js buffers pushed events until reconnection?
    - yes, with eventual timeout

# Environ Requirements

- supervisor to register manager/supervisor with
- standard paths: @home, @run, @tmp
- grouped async runner
- logging facility
- view publishing

# Code Editor

- click
    - add script/backend
    - remove script/backend
    - enable/disable script/backend
    - rename script/backend
    - save script/backend
    - exec script/backend
    - close editor
    - open/close screen
    - select script/backend/view
    - select group
    - select editor/view
    - sort script/backend/screens
- file events
    - add
    - updated
    - deleted
