import { createDockview, themeAbyss } from 'dockview-core'
import MicroModal from 'micromodal'
import { Pane } from 'tweakpane'
import Split from 'split.js'
import Editor from "./editor"

const state = {
    script: { selected: null, files: {} },
    backend: { selected: null, files: {} },
    editor: null, editors: {},
    panel: null, panels: {},
    logs: {}
}

export function Coder(hook) {

    const getFiles = (type) => { return state[type].files }
    const getFile = (type, name) => { return state[type].files[name] }
    const putFile = (type, name, entry) => { state[type].files[name] = entry }
    const delFile = (type, name) => { delete state[type].files[name] }
    const getSelected = (type) => { return state[type].selected }
    const putSelected = (type, name) => { state[type].selected = name }
    const getEditor = (path) => { return state.editors[path] }
    const putEditor = (path, editor) => { state.editors[path] = editor }
    const delEditor = (path) => { delete state.editors[path] }
    const getPanel = (type) => { return state.panels[type] }
    const putPanel = (type, panel) => { state.panels[type] = panel }

    const saveFile = (path, data) => { localStorage.setItem(`flex2:repo:${path}`, data) }
    const loadFile = (path) => { return localStorage.getItem(`flex2:repo:${path}`) }
    const joinPath = (type, name) => { return `${type}/${name}` }
    const splitPath = (path) => { return path.split('/') }

    const call = (component, fun, ...args) => {
        const inner = component.view._content
        inner[fun].call(inner, ...args)
    }

    class TabRenderer {
        constructor() {
            const el = document.createElement('div')
            el.className = 'coder-tab'
            this.el = el

            this.initialize = (params) => {
                const title = document.createElement('span')
                title.className = 'coder-tab-title'
                title.textContent = params.title
                this.el.appendChild(title)

                if (params.params.close) {
                    const close = document.createElement('button')
                    close.className = 'coder-tab-close'
                    close.title = 'Close editor'
                    close.textContent = '×'
                    close.addEventListener('click', (e) => {
                        const { type, name } = params.params
                        closeEditor(type, name)
                    })
                    this.el.appendChild(close)
                }

            }
        }

        get element() {
            return this.el
        }

        init(params) {
            this.initialize(params)
        }
    }

    class FileComponent {
        constructor() {
            const el = document.createElement('div')
            el.className = 'coder-file-panel'
            this.el = el

            const list = document.createElement('div')
            list.className = 'coder-file-panel-list'

            this.append = (el) => {
                list.appendChild(el)
            }

            this.initialize = (params) => {
                const type = params.params.type

                const header = document.createElement('div')
                header.className = 'coder-file-panel-header'
                this.el.appendChild(header)

                const title = document.createElement('div')
                title.className = 'coder-file-panel-title'
                title.textContent = params.title
                header.appendChild(title)

                if (params.params.add) {
                    const icon = document.createElement('div')
                    icon.classList.add('hero-document-plus', 'coder-file-panel-icon')
                    icon.title = `Add ${type}`
                    icon.addEventListener('click', () => {
                        hook.pushEvent('hook:add', { type })
                    })
                    header.appendChild(icon)
                }

                this.el.appendChild(list)
            }
        }

        get element() {
            return this.el
        }

        init(params) {
            this.initialize(params)
        }
    }

    class CodeComponent {
        constructor() {
            const id = crypto.randomUUID()

            const el = document.createElement('div')
            el.className = 'coder-file-editor'
            this.el = el

            const code = document.createElement('div')
            code.className = 'coder-file-editor-code'
            code.id = `coder-file-editor-code-${id}`
            el.appendChild(code)

            const logs = document.createElement('div')
            logs.className = 'coder-file-editor-logs'
            logs.id = `coder-file-editor-logs-${id}`
            el.appendChild(logs)

            const entry = ({ id, stamp, level, msg }) => {
                const entry = document.createElement('div')
                entry.classList.add('coder-file-editor-logs-entry')
                entry.classList.add(`coder-file-editor-logs-${level}`)
                entry.textContent = `${stamp} ${level} ${msg}`
                entry.id = `log_${id}`
                return entry
            }

            const autoscroll = () => {
                // macos work with just one last children
                // linux requires last two children (maybe the update sends them together)
                const lastChild = logs.lastElementChild
                const bottomExcess = logs.scrollHeight - logs.clientHeight - logs.scrollTop
                // console.log(lastChild, bottomExcess, lastChild.clientHeight)
                // clientHeight recommended for layout and scrolling
                // confirmed to work with tailwind break-all multi line logs
                if (lastChild) {
                    const prelastChild = lastChild.previousElementSibling
                    if (prelastChild) {
                        if (bottomExcess <= lastChild.clientHeight + prelastChild.clientHeight) {
                            logs.scrollTo(0, logs.scrollHeight)
                        }
                    }
                }
            }

            this.append = (params) => {
                // slight chance of duplicated just after init
                try { logs.appendChild(entry(params)) } catch (_) { }
                autoscroll()
            }

            this.replace = (data) => {
                const editor = this.el.editor
                if (editor.toString() != data) editor.replace(data)
            }

            this.initialize = (params) => {
                const { type, name } = params.params
                const path = joinPath(type, name)
                const key = `flex2:editor:${path}`
                const editor = new Editor(code, key, (editor) => {
                    const data = editor.toString()
                    // console.log(data)
                    hook.pushEvent('hook:save', { path, data })
                })
                editor.replace(loadFile(path))
                params.api.onDidActiveChange(() => {
                    // console.log("isActive", path, params.api.isActive)
                    if (params.api.isActive) {
                        editor.focus()
                        // autoscroll not working when not visible
                        logs.scrollTo(0, logs.scrollHeight)
                    }
                })

                const list = state.logs[path] || []
                for (const log of list) logs.appendChild(entry(log))
                if (list.length > 0) logs.appendChild(document.createElement('hr'))

                this.el.editor = editor

                setTimeout(() => {
                    Split(["#" + code.id, "#" + logs.id], { gutterSize: 1 })
                    // remove the initial fixed width added to remove flicker
                    code.classList.add('coder-file-editor-split')
                    logs.classList.add('coder-file-editor-split')
                }, 0)
            }
        }

        get element() {
            return this.el
        }

        init(params) {
            this.initialize(params)
        }
    }

    const api = createDockview(hook.el, {
        theme: themeAbyss,
        createComponent: (options) => {
            switch (options.name) {
                case 'file': return new FileComponent()
                case 'code': return new CodeComponent()
                default: throw 'Unknown component'
            }
        },
        createTabComponent: (options) => {
            return new TabRenderer()
        }
    })

    api.addEdgeGroup('left', {
        id: 'left',
        minimumSize: 200,
    })

    putPanel('script', api.addPanel({
        id: 'scripts',
        component: 'file',
        title: 'Scripts',
        tabComponent: 'default',
        params: { type: 'script', add: true },
        position: { referenceGroup: 'left' }
    }))

    putPanel('backend', api.addPanel({
        id: 'backends',
        component: 'file',
        inactive: true,
        title: 'Backends',
        tabComponent: 'default',
        params: { type: 'backend', add: true },
        position: { referenceGroup: 'left' }
    }))

    putPanel('screen', api.addPanel({
        id: 'screens',
        component: 'file',
        inactive: true,
        title: 'Screens',
        tabComponent: 'default',
        params: { type: 'screen' },
        position: { referenceGroup: 'left' }
    }))

    const createFile = (type, name, enabled) => {
        const path = joinPath(type, name)
        const panel = getPanel(type)
        const el = document.createElement('div')
        el.className = 'coder-file-panel-entry'

        const label = document.createElement('div')
        label.className = 'coder-file-panel-entry-label'

        const status = document.createElement('div')
        status.className = 'coder-file-panel-entry-status'
        if (enabled) status.classList.add('coder-file-panel-entry-status-enabled')
        const enabler = (enabled) => {
            if (enabled) status.classList.add('coder-file-panel-entry-status-enabled')
            else status.classList.remove('coder-file-panel-entry-status-enabled')
        }

        const file = document.createElement('div')
        file.className = 'coder-file-panel-entry-file'
        file.textContent = name
        file.addEventListener('click', () => { selectFile(type, name, true) })
        file.addEventListener('dblclick', () => { renameFile(type, name) })

        label.appendChild(status)
        label.appendChild(file)

        const actions = document.createElement('div')
        actions.className = 'coder-file-panel-entry-actions'

        const range = document.createElement('input')
        range.className = 'coder-file-panel-entry-range'
        range.title = 'Swipe right to delete'
        range.type = 'range'
        range.min = '0'
        range.max = '2'
        range.step = '1'
        range.value = '0'
        let value = 0
        let timer = null
        range.addEventListener('input', () => {
            if (timer) clearTimeout(timer)
            timer = null
            const diff = range.value - value
            if (diff != 1) { value = range.value = 0 }
            if (diff == 1) { value = range.value }
            timer = setTimeout(() => { value = range.value = 0 }, 500)
            if (range.value == range.max) hook.pushEvent('hook:del', { path })
        })

        const play = document.createElement('div')
        play.classList.add('hero-play', 'coder-file-entry-icon', 'coder-file-entry-icon-play')
        play.title = `Start ${type}`
        play.addEventListener('click', (e) => {
            e.stopPropagation()
            hook.pushEvent('hook:start', { path })
        })

        const stop = document.createElement('div')
        stop.classList.add('hero-stop', 'coder-file-entry-icon', 'coder-file-entry-icon-stop')
        stop.title = `Stop ${type}`
        stop.addEventListener('click', (e) => {
            e.stopPropagation()
            hook.pushEvent('hook:stop', { path })
        })

        actions.appendChild(play)
        actions.appendChild(stop)
        actions.appendChild(range)

        el.appendChild(label)
        el.appendChild(actions)

        call(panel, "append", el)
        return { el, enabler }
    }

    const unselectFile = (type) => {
        const files = getFiles(type)
        for (const [name, { el }] of Object.entries(files)) {
            el.classList.remove('coder-selected')
        }
        putSelected(type, null)
    }

    // add-click, file-click, editor-click
    const selectFile = (type, name, open) => {
        if (getSelected(type) == name) return
        const files = getFiles(type)
        for (const [name, { el }] of Object.entries(files)) {
            el.classList.remove('coder-selected')
        }
        const { el } = files[name]
        el.classList.add('coder-selected')
        putSelected(type, name)
        const panel = getPanel(type)
        if (open) openFile(type, name, panel)
    }

    const openFile = (type, name, panel) => {
        const path = joinPath(type, name)
        if (!getEditor(path)) createEditor(type, name, panel)
        getEditor(path).api.setActive()
    }

    // trigger with file label double click
    const renameFile = (type, name) => {
        const simple = name.replace(/\.exs$/, "");
        const params = { name: simple }
        const pane = new Pane({ container: document.getElementById('rename-content') })
        const n = pane.addBinding(params, 'name')
        const b = pane.addButton({ title: 'Rename' });
        b.on('click', () => {
            const value = params.name.trim()
            if (!/^[a-zA-Z][a-zA-Z0-9_-]+$/.test(value)) return
            const file = `${value}.exs`
            if (getFile(type, file)) return
            const path = joinPath(type, name)
            hook.pushEvent('hook:rename', { path, new: joinPath(type, file) })
            MicroModal.close('rename')
        })
        MicroModal.show('rename', { onClose: () => { pane.dispose() } })
        // tp-btnv_b required because there is a second hidden button
        // just shifting the focus generates the button click event!
        const input = document.querySelector('#rename input')
        const button = document.querySelector('#rename button.tp-btnv_b')
        input.addEventListener('keydown', (event) => {
            if (event.key === 'Enter') button.focus()
        })
        input.focus()
    }

    const initFiles = (type, names) => {
        const files = getFiles(type)
        const map = {}
        for (const name of names) {
            map[name] = name
        }
        for (const name of Object.keys(files)) {
            if (!Object.hasOwn(map, name)) {
                removeFile(type, name)
            }
        }
        for (const { name, enabled } of names) {
            if (!Object.hasOwn(files, name)) {
                putFile(type, name, createFile(type, name, enabled))
            }
        }
    }

    const createEditor = (type, name, panel) => {
        const path = joinPath(type, name)
        const position0 = { direction: 'right' }
        const position1 = {
            referencePanel: state.editor,
            direction: 'within'
        }
        // inactive or active event fires before adding to editors map
        const editor = api.addPanel({
            id: `code-${path}`,
            component: 'code',
            title: path,
            inactive: true,
            tabComponent: 'default',
            params: { close: true, type, name, panel },
            position: state.editor ? position1 : position0

        })
        putEditor(path, editor)
        // defer state.editor = editor to active change listener
        // editor.api.setActive() called by the selection logic
        editor.api.onDidActiveChange(() => {
            // emits both active false|true events
            // console.log("active", type, name, editor.api.isActive)
            if (!editor.api.isActive) return
            if (state.editor == editor) return
            state.editor = editor
            selectFile(type, name, false)
            // loop stopped by the selected editor check above
            // panel then editor
            panel.api.setActive()
            editor.api.setActive()
        })
    }

    const closeEditor = (type, name) => {
        // unselect file entry first or it will try
        // to open again when group gains focus after editor close
        if (getSelected(type) == name) unselectFile(type)
        const path = joinPath(type, name)
        const editor = getEditor(path)
        // console.log("close", type, name, path, editor)
        if (state.editor == editor) state.editor = null
        if (editor) delEditor(path)
        if (editor) editor.api.close()
    }

    const removeFile = (type, name) => {
        closeEditor(type, name)
        const { el } = getFile(type, name)
        delFile(type, name)
        el.remove()
    }

    const onPanelActiveChange = (type) => {
        const panel = getPanel(type)
        // console.log("active", type, panel.api.isActive)
        if (!panel.api.isActive) return
        if (state.panel == panel) return
        state.panel = panel
        // include screen panel in selected panel logic
        // check for add param last
        if (!panel.params.add) return
        const name = getSelected(type)
        if (!name) return
        const path = joinPath(type, name)
        const editor = getEditor(path)
        // do not check for last state.editor since
        // group click unselected editor
        // if (state.editor == editor) return
        editor.api.setActive()
    }

    for (const [type, panel] of Object.entries(state.panels)) {
        panel.api.onDidActiveChange(() => {
            onPanelActiveChange(type)
        })
    }

    // called both on mount and reconnected
    hook.handleEvent('hook:init', ({ files, logs }) => {
        // if expanded late in console, it contains pushed ones as well
        // console.log(logs) 
        const scripts = []
        const backends = []
        state.logs = logs // open editors preserver logs
        for (const { path, data, enabled } of files) {
            saveFile(path, data)
            const [type, name] = splitPath(path)
            if (type == 'script') scripts.push({ name, enabled })
            if (type == 'backend') backends.push({ name, enabled })
            const editor = getEditor(path)
            if (editor) call(editor, "replace", data)
        }

        initFiles('script', scripts)
        initFiles('backend', backends)
    })

    hook.handleEvent('hook:add', ({ path, data, enabled }) => {
        saveFile(path, data)
        state.logs[path] = []
        const [type, name] = splitPath(path)
        putFile(type, name, createFile(type, name, enabled))
        selectFile(type, name, true)
    })

    // includes new files as well
    hook.handleEvent('hook:updated', ({ path, data, enabled }) => {
        // console.log("updated", path, data, enabled)
        saveFile(path, data)
        state.logs[path] = state.logs[path] || []
        const [type, name] = splitPath(path)
        const entry = getFile(type, name)
        if (entry) entry.enabler(enabled)
        else putFile(type, name, createFile(type, name, enabled))
        const editor = getEditor(path)
        if (editor) call(editor, "replace", data)
    })

    hook.handleEvent('hook:deleted', ({ path }) => {
        // console.log("deleted", path)
        const [type, name] = splitPath(path)
        removeFile(type, name)
        delete state.logs[path]
    })

    // strict log policy, append only if path exists
    // fixme: send out of sync logs to global log viewer
    hook.handleEvent('hook:log', ({ id, path, stamp, level, msg }) => {
        // console.log("log", id, stamp, path, level, msg)
        const list = state.logs[path]
        if (list) list.push({ id, stamp, level, msg })
        const editor = getEditor(path)
        if (editor) call(editor, "append", { id, stamp, level, msg })
    })

    // remove flicker, 10ms works on macos m1, 0ms wont work
    setTimeout(() => { hook.el.classList.remove('coder-invisible') }, 100)
    window.addEventListener('DOMContentLoaded', () => MicroModal.init())
}
