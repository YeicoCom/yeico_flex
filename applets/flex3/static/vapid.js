// reload SW requires clicking update in the devtools/application/service-workers section
// a new vapid pubkey required unsubscribing from the previous one
// If received in http://localhost:4080/ console but not shown go to:
// System Settings > Notifications > Google Chrome has "Allow Notifications"
// Check Focus / Do Not Disturb is disabled or add Chrome to the exceptions
// https://vapidkeys.com/

function consoleLog(...args) {
    console.log(args)
}

self.addEventListener("push", (event) => {
    consoleLog("SW push received", event)
    const json = event.data.json()
    const promise = self.registration.showNotification(json.title, json.options)
    event.waitUntil(promise)
})

self.addEventListener("message", (event) => {
    if (event.data.indexOf("subscribe:") == 0) {
        const pubkey = event.data.substring(10)
        consoleLog("SW subscription request", pubkey)
        subscribe(pubkey, event.ports[0])
    }
})

function subscribe(pubkey, port) {
    self.registration.pushManager.subscribe({
        applicationServerKey: urlBase64ToUint8Array(pubkey),
        userVisibleOnly: true,
    }).then(sub => {
        consoleLog("SW subscription ok", sub)
        port.postMessage(JSON.stringify(sub))
    }).catch(err => {
        consoleLog("SW subscription error", err)
    })
}

function urlBase64ToUint8Array(base64String) {
    var padding = "=".repeat((4 - base64String.length % 4) % 4)
    var base64 = (base64String + padding)
        .replace(/\-/g, "+")
        .replace(/_/g, "/")
    var rawData = atob(base64)
    var outputArray = new Uint8Array(rawData.length)
    for (var i = 0; i < rawData.length; ++i) {
        outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
}
