import 'phoenix_html'
import { Socket } from 'phoenix'
import { LiveSocket } from 'phoenix_live_view'
import topbar from 'topbar'

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

const resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
        const target = entry.target
        if (target.resizeListener) {
            target.resizeListener(target)
        }
    }
})

// macos m1 disconnects the websocket after ~3m idle
// and pheonix reconnects immediatelly but hook.mount
// is not called, just the disconnected/reconnected
// on the server side a single mount with connected? true
const hooks = {
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
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute('content')
const params = { _csrf_token: csrfToken, ...initialParams() }
let liveSocket = new LiveSocket('/live', Socket, { hooks, params })
topbar.config({ barColors: { 0: '#84cc16' }, shadowColor: 'rgba(0, 0, 0, .3)' })
window.addEventListener('phx:page-loading-start', _info => topbar.show(300))
window.addEventListener('phx:page-loading-stop', _info => topbar.hide())
liveSocket.connect()
