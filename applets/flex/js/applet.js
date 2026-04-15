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

const Hooks = {
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
            const elements = this.el.elements
            const len = elements.length
            for (let i = 0; i < len; i++) {
                const el = elements[i]
                const isSelect = el instanceof HTMLSelectElement
                const isInput = el instanceof HTMLInputElement
                const isSubmit = el.type === "submit"
                if (isSelect || isInput) {
                    el.addEventListener('keydown', (event) => {
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
                    })
                }
            }
        }
    },
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken, ...initialParams() } })
topbar.config({ barColors: { 0: "#84cc16" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
liveSocket.connect()
