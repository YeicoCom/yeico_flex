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

export default {
    mounted() {
        setFocus(this.el)
    }
}