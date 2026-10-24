export default {
    mounted() {
        const input = document.getElementById(this.el.dataset.input)
        const key = this.el.dataset.key
        this.el.addEventListener("click", () => {
            input.focus()
            const startPos = input.selectionStart
            const endPos = input.selectionEnd
            const originalValue = input.value
            switch (key) {
                case "Backspace": {
                    if (endPos > startPos) {
                        input.value = originalValue.slice(0, startPos) + originalValue.slice(endPos)
                        const newCaretPos = startPos
                        input.setSelectionRange(newCaretPos, newCaretPos)

                    } else if (startPos > 0) {
                        input.value = originalValue.slice(0, startPos - 1) + originalValue.slice(endPos)
                        const newCaretPos = startPos - 1
                        input.setSelectionRange(newCaretPos, newCaretPos)
                    }
                    break
                }
                default: {
                    input.value = originalValue.slice(0, startPos) + key + originalValue.slice(endPos)
                    const newCaretPos = startPos + key.length
                    input.setSelectionRange(newCaretPos, newCaretPos)
                    break
                }
            }
        })
    }
}