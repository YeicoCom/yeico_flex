
function decodeJWT(token) {
    let base64Url = token.split(".")[1]
    let base64 = base64Url.replace(/-/g, "+").replace(/_/g, "/")
    let jsonPayload = decodeURIComponent(
        atob(base64)
            .split("")
            .map(function (c) {
                return "%" + ("00" + c.charCodeAt(0).toString(16)).slice(-2)
            })
            .join("")
    )
    return JSON.parse(jsonPayload)
}

let gauthGlobals = {}

window.gauthRegisterHook = function (hook) {
    gauthGlobals.hook = hook
}

window.gauthHandleResponse = function (response) {
    const profile = decodeJWT(response.credential)
    if (gauthGlobals.hook) gauthGlobals.hook(response, profile)
}

window.gauthLoadClient = function () {
    // just checking existance wont make the button reapear
    var prev = document.getElementById("g_gsi_script_loader")
    if (prev) prev.remove()
    var script = document.createElement("script")
    script.id = "g_gsi_script_loader"
    script.src = "https://accounts.google.com/gsi/client"
    document.head.appendChild(script);
}
