function runSafe(fun) {
    try {
        fun()
    } catch (err) {
        console.error(err);
    }
}

export default {
    mounted() {
        this.handleEvent("copy:text", ({ text }) => {
            runSafe(() => { navigator.clipboard.writeText(text) })
        })
    }
}