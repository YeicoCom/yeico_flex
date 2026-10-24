// set focus and move caret to end
function setFocus(el) {
    el.focus()
    // number input does not support selection
    // submit buttons get detached from form
    if (el.setSelectionRange) {
        const type = el.type
        el.type = "text"
        const end = el.value.length
        el.setSelectionRange(end, end)
        el.type = type
    }
}

function enterNavigate(el) {
    const elements = el.elements
    const len = elements.length
    for (let i = 0; i < len; i++) {
        const el = elements[i]
        const isSelect = el instanceof HTMLSelectElement
        const isInput = el instanceof HTMLInputElement
        const isArea = el instanceof HTMLTextAreaElement
        const isSubmit = el.type === "submit"
        if (isSelect || isInput || isArea) {
            const listener = (event) => {
                if (event.key === "Enter" && !event.shiftKey) {
                    if (!isSubmit || el.disabled) {
                        event.preventDefault();
                        for (let j = 1; j < len; j++) {
                            const ni = (i + j) % len;
                            const nel = elements[ni]
                            if (nel.disabled) continue
                            setFocus(nel)
                            if (el === document.activeElement) continue
                            break
                        }
                    }
                }
            }
            if (el.previousListener) {
                // listeners preserved on update
                el.removeEventListener("keydown", el.previousListener)
            }
            el.previousListener = listener
            el.addEventListener("keydown", listener)
        }
    }
}

export default {
    mounted() {
        enterNavigate(this.el)
    },
    updated() {
        enterNavigate(this.el)
    }
}