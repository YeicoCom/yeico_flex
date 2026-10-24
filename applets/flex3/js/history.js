
export default {
    mounted() {
        this.el.focus()
        this.el.history = { line: 0, lines: [this.el.value] }
        this.el.addEventListener('keydown', (event) => {
            let { line, lines } = this.el.history
            let len = 0
            switch (event.key) {
                case "ArrowUp":
                    event.preventDefault() //moves to start and end of line
                    line = Math.min(line + 1, lines.length - 1)
                    this.el.value = lines[line]
                    this.el.history = { line, lines }
                    len = this.el.value.length
                    this.el.setSelectionRange(len, len)
                    break;
                case "ArrowDown":
                    event.preventDefault() //moves to start and end of line
                    line = Math.max(line - 1, 0)
                    this.el.value = lines[line]
                    this.el.history = { line, lines }
                    len = this.el.value.length
                    this.el.setSelectionRange(len, len)
                    break;
                case "Enter":
                    lines[0] = this.el.value
                    lines = ["", ...lines]
                    this.el.history = { line: 0, lines }
                    break;
            }
        })
        this.el.addEventListener('input', (event) => {
            let { line, lines } = this.el.history
            lines[0] = this.el.value
            this.el.history = { line: 0, lines }
        })
    },
    updated() {
        this.el.focus()
    }
}