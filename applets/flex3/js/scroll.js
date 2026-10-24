
export default {
    mounted() {
        this.el.scrollTo(0, this.el.scrollHeight)
    },
    updated() {
        this.el.scrollTo(0, this.el.scrollHeight)
    }
}