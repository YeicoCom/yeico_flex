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

const Hooks = {
    AutoFocus: {
        mounted() {
            this.el.focus()
            // selects all the text in an input or textarea
            if (this.el.select) this.el.select()
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
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { hooks: Hooks, params: { _csrf_token: csrfToken, ...initialParams() } })
topbar.config({ barColors: { 0: "#84cc16" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
liveSocket.connect()
