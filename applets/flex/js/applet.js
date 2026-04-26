import "phoenix_html"
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "topbar"

function initialParams() {
    return {
        width: window.innerWidth,
        height: window.innerHeight,
        href: window.location.href,
        site: localStorage.getItem("login:site"),
        locale: Intl.NumberFormat().resolvedOptions().locale,
        tzname: Intl.DateTimeFormat().resolvedOptions().timeZone,
        tzoffset: -(new Date().getTimezoneOffset() / 60),
    }
}

function setFocus(el) {
    el.focus()
    // number input does not support selection
    // submit buttons get detached from form
    if (el.setSelectionRange) {
        const type = el.type
        el.type = "text"
        const end = el.value.length
        el.setSelectionRange(end, end)
        el.type = type
    }
}

function enterNavigate(el) {
    const elements = el.elements
    const len = elements.length
    for (let i = 0; i < len; i++) {
        const el = elements[i]
        const isSelect = el instanceof HTMLSelectElement
        const isInput = el instanceof HTMLInputElement
        const isSubmit = el.type === "submit"
        if (isSelect || isInput) {
            const listener = (event) => {
                if (event.key === 'Enter') {
                    if (!isSubmit || el.disabled) {
                        event.preventDefault();
                        for (let j = 1; j < len; j++) {
                            const ni = (i + j) % len;
                            const nel = elements[ni]
                            if (nel.disabled) continue
                            setFocus(nel)
                            if (el === document.activeElement) continue
                            break
                        }
                    }
                }
            }
            if (el.previousListener) {
                // listeners preserved on update
                el.removeEventListener('keydown', el.previousListener)
            }
            el.previousListener = listener
            el.addEventListener('keydown', listener)
        }
    }
}

const resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
        const target = entry.target
        if (target.resizeListener) {
            target.resizeListener(target)
        }
    }
})

const hooks = {
    AutoFocus: {
        mounted() {
            setFocus(this.el)
        }
    },
    AutoScroll: {
        mounted() {
            this.el.scrollTo(0, this.el.scrollHeight)
        },
        updated() {
            const lastChild = this.el.lastElementChild
            const bottomExcess = this.el.scrollHeight - this.el.clientHeight - this.el.scrollTop
            //clientHeight recommended for layout and scrolling
            //confirmed to work with tailwind break-all multi line logs
            if (lastChild && bottomExcess <= lastChild.clientHeight) {
                this.el.scrollTo(0, this.el.scrollHeight)
            }
        }
    },
    EnterNavigation: {
        mounted() {
            enterNavigate(this.el)
        },
        updated() {
            // point editor is dynamic
            enterNavigate(this.el)
        }
    },
    LineHistory: {
        mounted() {
            setFocus(this.el)
            const key = `history-${this.el.dataset.key}`
            this.handleEvent("history:append", (params) => {
                let { line, lines } = this.el.history
                lines[0] = params.line
                // Set is ordered by insertion
                lines = ["", ...new Set(lines)]
                this.el.value = ""
                this.el.history = { line: 0, lines }
                localStorage.setItem(key, JSON.stringify(lines))
                setTimeout(() => setFocus(this.el), 0)
            })
            let lines = JSON.parse(localStorage.getItem(key) || "[0]")
            lines[0] = this.el.value
            this.el.history = { line: 0, lines: lines }
            this.el.addEventListener('keydown', (event) => {
                let { line, lines } = this.el.history
                let len = 0
                switch (event.key) {
                    case "ArrowUp":
                        event.preventDefault() //moves to start and end of line
                        line = Math.min(line + 1, lines.length - 1)
                        this.el.value = lines[line]
                        this.el.history = { line, lines }
                        len = this.el.value.length
                        this.el.setSelectionRange(len, len)
                        break;
                    case "ArrowDown":
                        event.preventDefault() //moves to start and end of line
                        line = Math.max(line - 1, 0)
                        this.el.value = lines[line]
                        this.el.history = { line, lines }
                        len = this.el.value.length
                        this.el.setSelectionRange(len, len)
                        break;
                }
            })
            //user typing
            this.el.addEventListener('input', (event) => {
                let { line, lines } = this.el.history
                lines[0] = this.el.value
                this.el.history = { line: 0, lines }
            })
        },
    },
    DesignFrame: {
        mounted() {
            const frame = this.el
            const pushSize = (el) => {
                const width = el.clientWidth
                const height = el.clientHeight
                const prev = el.sizeState || {}
                // updates from server trigger the event even if same size
                if (width == prev.width && height == prev.height) return
                el.sizeState = { width, height }
                this.pushEvent("frame:resize", { width, height })
            }
            frame.ignoreClickUntil = Date.now()
            frame.addEventListener("click", (e) => {
                const menu = document.getElementById("design_menu")
                if (menu && menu.contains(e.srcElement)) return
                if (Date.now() < frame.ignoreClickUntil) return
                const rect = frame.getBoundingClientRect()
                const x = e.clientX - rect.x
                const y = e.clientY - rect.y
                this.pushEvent("frame:click", { x, y })
            })
            frame.resizeListener = pushSize
            resizeObserver.observe(frame)
            pushSize(frame)
        },
        updated() {
            const frame = this.el
            if (frame.childrenSetup) return
            const panel = document.getElementById("design_panel")
            const port = document.getElementById("design_port")
            if (!panel) return
            if (!port) return
            port.addEventListener("wheel", (e) => {
                if (!panel.contains(e.srcElement)) return
                port.wheelState = port.wheelState || { dx: 0, dy: 0 }
                const rect = port.getBoundingClientRect()
                const x = e.clientX - rect.x
                const y = e.clientY - rect.y
                const dx = e.deltaX + port.wheelState.dx
                const dy = e.deltaY + port.wheelState.dy
                port.wheelState.dx = dx
                port.wheelState.dy = dy
                port.wheelState.pending = () => {
                    this.pushEvent("frame:wheel", { x, y, dx, dy })
                }
                if (!port.wheelState.timer) {
                    port.wheelState.timer = setTimeout(() => {
                        if (port.wheelState.pending) port.wheelState.pending()
                        port.wheelState = null
                    }, 100)
                }
            })
            port.addEventListener("pointerdown", (e) => {
                if (!panel.contains(e.srcElement)) return
                const rect = port.getBoundingClientRect()
                const ox = e.clientX - rect.x
                const oy = e.clientY - rect.y
                const pid = e.pointerId
                const moved = false
                port.dragState = { ox, oy, pid, moved }
                port.setPointerCapture(pid)
                this.pushEvent("frame:drag", { mx: ox, my: oy, ox, oy, e: "down", m: moved })
            })
            port.addEventListener("mousemove", (e) => {
                if (port.dragState) {
                    const rect = port.getBoundingClientRect()
                    const mx = e.clientX - rect.x
                    const my = e.clientY - rect.y
                    port.dragState.moved = true
                    const { ox, oy, moved } = port.dragState
                    port.dragState.pending = () => {
                        this.pushEvent("frame:drag", { mx, my, ox, oy, e: "move", m: moved })
                    }
                    if (!port.dragState.timer) {
                        port.dragState.timer = setTimeout(() => {
                            if (port.dragState.pending) port.dragState.pending()
                            port.dragState.timer = null
                            port.dragState.pending = null
                        }, 100)
                    }
                }
            })
            port.addEventListener("pointerup", (e) => {
                if (port.dragState) {
                    const { ox, oy, pid, moved } = port.dragState
                    if (port.dragState.timer) clearTimeout(port.dragState.timer)
                    if (moved) frame.ignoreClickUntil = Date.now() + 100
                    const rect = port.getBoundingClientRect()
                    const mx = e.clientX - rect.x
                    const my = e.clientY - rect.y
                    port.releasePointerCapture(pid)
                    this.pushEvent("frame:drag", { mx, my, ox, oy, e: "up", m: moved })
                    port.dragState = null
                }
            })
            frame.childrenSetup = true
        },
        reconnected() {
            // it gets stuck
            window.location.reload()
        }
    },
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const params = { _csrf_token: csrfToken, ...initialParams() }
let liveSocket = new LiveSocket("/live", Socket, { hooks, params })
topbar.config({ barColors: { 0: "#84cc16" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
liveSocket.connect()
