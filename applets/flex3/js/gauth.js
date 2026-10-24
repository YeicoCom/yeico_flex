
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

const gauthGlobals = {}

// declared as data-callback at login/g_id_onload
// requires to be globally visible
window.gauthHandleResponse = function (response) {
    const profile = decodeJWT(response.credential)
    if (gauthGlobals.hook) gauthGlobals.hook(response, profile)
}

// entry point at mount
function gauthLoadClient() {
    // just checking existance wont make the button reapear
    var prev = document.getElementById("g_gsi_script_loader")
    if (prev) prev.remove()
    var script = document.createElement("script")
    script.id = "g_gsi_script_loader"
    script.src = "https://accounts.google.com/gsi/client"
    script.async = true
    script.defer = true
    script.onload = () => {
        // all this because the g-button conflicts with daisyui and paints
        // an ugly background around it when user already signed in the browser
        // https://developers.google.com/identity/sign-in/web/build-button

        // google.accounts.id.prompt()
        // shows top-rigth corner login popup once
        // wont show again if closed with log: FedCM was disabled
        // reenable here chrome://settings/content/federatedIdentityApi

        // not needed after the wait for iframe below
        // google.accounts.id.renderButton(
        //     document.getElementById("gauth_button_original"),
        //     {
        //         theme: "outline",
        //         shape: "pill"
        //     }
        // )

        // confirmed to work in chrome / firefox in macos m1
        // with absolute positioning: it gets moved around if initially visible
        // with same grid cell: gbutton shows for an instant when relayout is triggered by hidden removal
        // waiting for iframe to restore opacity completely prevents the gbutton showing for an instant
        // working with opacity instead of hidded minimizes relayout flickers
        // make the overlapping button large enough to minimize relayout flickers
        const timer = setInterval(() => {
            if (document.getElementById("gauth_button_original").querySelector('iframe')) {
                document.getElementById("gauth_button_layers").style.opacity = "1"
                document.getElementById("gauth_button_custom").style.opacity = "1"
                clearInterval(timer)
            }
        }, 1000)
    }
    document.head.appendChild(script);
}

export default {
    mounted() {
        // redirect somewhere else
        this.handleEvent("gauth:href", ({ href }) => {
            location.href = href
        })
        // receive user credentials
        gauthGlobals.hook = (response, profile) => {
            this.pushEvent("gauth:auth", { ...profile, ...response })
        }
        // trigger button loading
        setTimeout(gauthLoadClient, 100)
    }
}
