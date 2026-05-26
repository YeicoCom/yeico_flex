import { JSBarcode } from "jsbarcode"

// https://www.npmjs.com/package/jsbarcode
class FlexBarcode extends HTMLElement {

    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    static get observedAttributes() {
        return [
            "data-displayvalue",
            "data-textmargin",
            "data-fontsize",
            "data-margin",
            "data-text",
            "data-width",
            "data-height",
            "data-format",
            "data-value",
        ]
    }

    #rebuildElement() {
        this.shadowRoot.innerHTML = "<svg/>"
        const svg = this.shadowRoot.firstChild
        for (const name of FlexBarcode.observedAttributes) {
            const value = this.getAttribute(name)
            if (value != null) svg.setAttribute(name, value)
        }
        // there are invalid characters for certain barcode types
        try { JsBarcode(svg).init() } catch (e) { console.log(e) }
    }

    connectedCallback() {
        this.#rebuildElement()
    }

    attributeChangedCallback(attrName, oldVal, newVal) {
        this.#rebuildElement()
    }
}

window.customElements.define("flex-barcode", FlexBarcode);
