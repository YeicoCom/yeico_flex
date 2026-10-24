const resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
        const target = entry.target
        if (target.resizeListener) {
            target.resizeListener(target)
        }
    }
})

export default {
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
}