import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import Sparkline from "sparklines"
import { formatHex } from 'culori'
import topbar from 'topbar'
import "./gauth"

if (!navigator.userAgent.includes('YeicoTerminal')) {
    document.body.style.animation = 'none'
}

function decodeArgs() {
    const script = document.getElementById("applet.js")
    if (!script) return {}
    const args64 = script.dataset.args
    if (!args64) return {}
    const argsJson = atob(args64)
    return JSON.parse(argsJson)
}

const args = decodeArgs()

function initialParams() {
    return {
        width: window.innerWidth,
        height: window.innerHeight,
        href: window.location.href,
        locale: Intl.NumberFormat().resolvedOptions().locale,
        tzname: Intl.DateTimeFormat().resolvedOptions().timeZone,
        tzoffset: -(new Date().getTimezoneOffset() / 60),
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

// set focus and move caret to end
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

function runSafe(fun) {
    try {
        fun()
    } catch (err) {
        console.error(err);
    }
}

function enterNavigate(el) {
    const elements = el.elements
    const len = elements.length
    for (let i = 0; i < len; i++) {
        const el = elements[i]
        const isSelect = el instanceof HTMLSelectElement
        const isInput = el instanceof HTMLInputElement
        const isArea = el instanceof HTMLTextAreaElement
        const isSubmit = el.type === "submit"
        if (isSelect || isInput || isArea) {
            const listener = (event) => {
                if (event.key === "Enter" && !event.shiftKey) {
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
                el.removeEventListener("keydown", el.previousListener)
            }
            el.previousListener = listener
            el.addEventListener("keydown", listener)
        }
    }
}

function consoleLog(...args) {
    console.log(args)
}

// macos m1 disconnects the websocket after ~3m idle
// and pheonix reconnects immediatelly but hook.mount
// is not called, just the disconnected/reconnected
// on the server side a single mount with connected? true
const hooks = {
    Focus: {
        mounted() {
            setFocus(this.el)
        }
    },
    Form: {
        mounted() {
            enterNavigate(this.el)
        },
        updated() {
            enterNavigate(this.el)
        }
    },
    Spark: {
        // https://github.com/mariusGundersen/sparkline
        // https://github.com/mariusGundersen/sparkline/blob/909da5007d1c46a35b17a4911dbfb40dc0f8ca3b/source/sparkline.js#L40
        mounted() {
            // JSON.parse returns object and push method is not found
            const data = Array.from(JSON.parse(this.el.dataset.set))
            const maxlen = parseInt(this.el.dataset.maxlen)
            const sindex = parseInt(this.el.dataset.index)
            const dotRadius = parseInt(this.el.dataset.dotRadius) || 2.5
            const styles = window.getComputedStyle(this.el)
            const width = parseInt(styles.width)
            const height = parseInt(styles.height)
            const lineColor = this.el.dataset.lineColor || formatHex(styles.color)
            const fillBelow = this.el.dataset.fillBelow || false
            const endColor = this.el.dataset.endColor || lineColor
            const minValue = this.el.dataset.minValue
            const maxValue = this.el.dataset.maxValue
            const opts = { width, height, lineColor, endColor, dotRadius, fillBelow, minValue, maxValue }
            // console.log(opts)
            const spark = new Sparkline(this.el, opts)
            this.handleEvent("spark:add", ({ index, chunk }) => {
                if (index != sindex) return;
                data.push(...chunk)
                while (data.length > maxlen) data.shift()
                spark.draw(data)
            })
            spark.draw(data)
        },
    },
    Clipboard: {
        mounted() {
            this.handleEvent("clipboard:copy", ({ text }) => {
                runSafe(() => { navigator.clipboard.writeText(text) })
            })
        }
    },
    Resize: {
        mounted() {
            const pushSize = (el) => {
                const width = el.clientWidth
                const height = el.clientHeight
                this.pushEvent('hook:resize', { width, height })
            }
            this.el.resizeListener = pushSize
            this.el.pushSize = () => { pushSize(this.el) }
            resizeObserver.observe(this.el)
            pushSize(this.el)
        },
        reconnected() {
            this.el.pushSize()
        }
    },
    Theme: {
        mounted() {
            const query = window.matchMedia('(prefers-color-scheme: dark)');
            const pushTheme = (query) => {
                const theme = query.matches ? "dark" : "light"
                this.pushEvent('hook:theme', { theme })
            }
            this.el.pushTheme = () => { pushTheme(query) }
            query.addEventListener('change', (query) => { pushTheme(query) });
            pushTheme(query)
        },
        reconnected() {
            this.el.pushTheme()
        }
    },
    Keypad: {
        mounted() {
            const input = document.getElementById(this.el.dataset.input)
            const key = this.el.dataset.key
            this.el.addEventListener("click", () => {
                input.focus()
                const startPos = input.selectionStart
                const endPos = input.selectionEnd
                const originalValue = input.value
                switch (key) {
                    case "Backspace": {
                        if (endPos > startPos) {
                            input.value = originalValue.slice(0, startPos) + originalValue.slice(endPos)
                            const newCaretPos = startPos
                            input.setSelectionRange(newCaretPos, newCaretPos)

                        } else if (startPos > 0) {
                            input.value = originalValue.slice(0, startPos - 1) + originalValue.slice(endPos)
                            const newCaretPos = startPos - 1
                            input.setSelectionRange(newCaretPos, newCaretPos)
                        }
                        break
                    }
                    default: {
                        input.value = originalValue.slice(0, startPos) + key + originalValue.slice(endPos)
                        const newCaretPos = startPos + key.length
                        input.setSelectionRange(newCaretPos, newCaretPos)
                        break
                    }
                }
            })
        }
    },
    Gauth: {
        mounted() {
            this.handleEvent("gauth:href", ({ href }) => {
                window.location.href = href
            })
            gauthRegisterHook((response, profile) => {
                this.pushEvent("gauth:auth", { ...profile, ...response })
            })
            setTimeout(gauthLoadClient, 100)
        }
    },
    Vapid: {
        mounted() {
            const subscribe_to_vapid = (pubkey) => {
                consoleLog("App requesting permission")
                Notification.requestPermission((result) => {
                    consoleLog("App permission", result)
                    if (result != "granted") return
                    const channel = new MessageChannel()
                    channel.port1.onmessage = (event) => {
                        localStorage.setItem("vapid:subscription", event.data)
                        consoleLog("App subscription upload", JSON.parse(event.data))
                        this.pushEvent("hook:vapid", JSON.parse(event.data))
                    }
                    navigator.serviceWorker
                        .register(`${args.static}/vapid.js`).then((reg) => {
                            consoleLog("App sw register OK")
                            //safari null exception on first registration
                            const retry = (self, toms, check, success) => {
                                if (toms <= 0) {
                                    consoleLog("App retry failure")
                                    return
                                }
                                consoleLog("App retry...")
                                if (check()) success()
                                else setTimeout(() => {
                                    self(self, toms - 100, check, success)
                                }, 100)
                            }
                            retry(retry, 2000, () => { return reg.active }, () => {
                                reg.active.postMessage(`subscribe:${pubkey}`, [channel.port2])
                            })
                        }).catch((err) => {
                            consoleLog("App sw register ERROR", err)
                        });
                })
            }
            // server side triggering from gesture for safari
            this.handleEvent("vapid:enable", (params) => {
                localStorage.removeItem("vapid:subscription")
                subscribe_to_vapid(params.pubkey)
            })
            this.handleEvent("vapid:disable", (params) => {
                consoleLog("App sw unregistering...")
                localStorage.removeItem("vapid:subscription")
                // reg.pushManager.getSubscription().then((subscription) => { subscription.unsubscribe() })
                // in some cases unregistering the whole service worker is requiered
                // and such actions is only possible from the devtools
                navigator.serviceWorker.getRegistrations().then(registrations => {
                    for (const registration of registrations) {
                        // prevent cross contamination with another applet
                        const url = new URL(registration.scope)
                        if (url.pathname == args.static) {
                            registration.unregister()
                        }
                    }
                })
            })
            const data = localStorage.getItem("vapid:subscription")
            if (data) this.pushEvent("hook:vapid", JSON.parse(data))
        },
        reconnected() {
            const data = localStorage.getItem("vapid:subscription")
            if (data) this.pushEvent("hook:vapid", JSON.parse(data))
        }
    }
}

const barco = args.barco || "#84cc16"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const params = { _csrf_token: csrfToken, ...initialParams() }
let liveSocket = new LiveSocket('/live', Socket, { hooks, params })
topbar.config({ barColors: { 0: barco }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', _info => topbar.show(300))
window.addEventListener('phx:page-loading-stop', _info => topbar.hide())
liveSocket.connect()
