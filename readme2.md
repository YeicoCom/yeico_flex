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
- Script/Backend Daemons
- Daemons Children

# Fixme

- [ ] use daemon clean to wait for all runner defers to complete
- [ ] no output from script nested entity runner

- [ ] Runners clean not being called on applet stop (to restart)
    - no posible to clean super with applet defer (asyncs are killed before defers are awaited)
- [-] Backend tmp and permanent storage. 
    - tmp yes, permanent nope, it would mean clean need to leaving things behind
- [ ] log: make script/backend logs show up on web ide and terminal dev console
- [ ] log: make script/backend children logs show up on web ide and terminal dev console
- [ ] log: ensure exceptions shows module and fun number
- [ ] log: capture all script stdio
- [ ] implement backend runner
- [ ] implement screen browser and embedded viewer
- [ ] backend mix install funny broken latin1 macos output 
- [ ] support ansi escapes in web log viewer
- [ ] applet: loop to sleep only remaing rdms
- [ ] applet: runner supervisor to register a timestamp for Flex2.Print.tasks
- [ ] applet: async(fun0, opts) and async(fun1, arg, opts)
- [ ] applet: loop(fun0, opts) and loop(fun1, arg, opts)
- [ ] applet: all applets must restart if a dep is restarted (mdb, udb, ...)
    -  terminal restarts if applet app does? 
    -  mmm... terminal and applet app supers are one_for_one!
- [ ] Flex2.Live.view to register and broadcast path
- [ ] Clean before start on first run. 
- [ ] Defer based supervisor.

- [x] current daemon kill on file delete wont call runner clean
    - now it does by calling Runner.kill(context) instead of direct task kill
- [ ] current daemon kill on file delete wont cascade call runner clean to script created entities

- [ ] autoscroll goes to top instead of bottom on non active panel/log-viewer
- [ ] no use for entity:stage and entity:error?
- [ ] what is runner name being used for?
    - observable map has adb?
- [ ] Scrollbars with diverse styling chrome/safari
- [ ] Move to supervisor for repo/buffer/super?
- [ ] app/module registration and cleanup?
- [ ] addEdgeGroup not honoring initialSize
- [ ] Dockview how to persist only edge groups size?
- [ ] Backends add icon out of sigth on load
    - check demo src https://dockview.dev/demo/?theme=abyss
    - only happens when there is a file listed
- [ ] Flicker on non active editor close (file selection moves too fast)
- [ ] Integrate the log viewer to the right of the code editor itself
- [ ] Screen funs not shown on macos woke up (nil size?)
- [ ] Each entity registers a print method to dump its index
- [ ] Entity stage and error
    - entity:stage:ID nil,0,1 handled by the runner
    - entity:error:ID string fully handled by the entity
    - no really relevant?
- [ ] Function based entities
- [ ] Elixir backend entity
- [ ] Modbus master entity
- [ ] Modbus slave entity
- [ ] Live screen entity
- [ ] Flow logic entity
- [ ] Entity log viewer
- [ ] Entity browser
- [ ] File upload
- [ ] Drop dockview: custom svelte?
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
