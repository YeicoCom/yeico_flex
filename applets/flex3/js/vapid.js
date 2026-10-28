import Args from "./args"

function consoleLog(...args) {
    console.log(args)
}

export default {
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
                    .register("/applets/flex3/vapid.js").then((reg) => {
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
                    if (url.pathname == "/applets/flex3") {
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