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

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken, ...initialParams() } })
topbar.config({ barColors: { 0: "#84cc16" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())
liveSocket.connect()
