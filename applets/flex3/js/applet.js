import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from 'topbar'

import Args from "./args"
import Copy from "./copy"
import Focus from "./focus"
import Form from "./form"
import Gauth from "./gauth"
import History from "./history"
import Keypad from "./keypad"
import Resize from "./resize"
import Scroll from "./scroll"
import Spark from "./spark"
import Theme from "./theme"
import Vapid from "./vapid"

// macos m1 disconnects the websocket after ~3m idle
// and pheonix reconnects immediatelly but hook.mount
// is not called, just the disconnected/reconnected
// on the server side a single mount with connected? true
const hooks = {
    Copy,
    Focus,
    Form,
    Gauth,
    History,
    Keypad,
    Resize,
    Scroll,
    Spark,
    Theme,
    Vapid
}

if (!navigator.userAgent.includes('YeicoTerminal')) {
    document.body.style.animation = 'none'
}

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

const barco = Args.barco || "#84cc16"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const params = { _csrf_token: csrfToken, ...initialParams() }
let liveSocket = new LiveSocket('/live', Socket, { hooks, params })
topbar.config({ barColors: { 0: barco }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', _info => topbar.show(300))
window.addEventListener('phx:page-loading-stop', _info => topbar.hide())
liveSocket.connect()
