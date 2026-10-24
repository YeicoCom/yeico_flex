function decodeArgs() {
    const script = document.getElementById("applet.js")
    if (!script) return {}
    const args64 = script.dataset.args
    if (!args64) return {}
    const argsJson = atob(args64)
    return JSON.parse(argsJson)
}

export default decodeArgs()
