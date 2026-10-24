export default {
    mounted() {
        const query = window.matchMedia('(prefers-color-scheme: dark)');
        const pushTheme = (query) => {
            const theme = query.matches ? "dark" : "light"
            this.pushEvent('hook:theme', { theme })
        }
        this.el.pushTheme = () => { pushTheme(query) }
        query.addEventListener('change', (query) => { pushTheme(query) });
        pushTheme(query)
    },
    reconnected() {
        this.el.pushTheme()
    }
}