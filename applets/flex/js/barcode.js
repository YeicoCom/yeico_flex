import { JSBarcode } from "jsbarcode"

// https://www.npmjs.com/package/jsbarcode
class FlexBarcode extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({ mode: 'open' })
    }

    static get observedAttributes() {
        return [
            'data-format',
            'data-value',
        ]
    }

    #updateBarcode() {
        this.shadowRoot.innerHTML = "<svg/>"
        const svg = this.shadowRoot.firstChild
        for (const attr of this.attributes) {
            svg.setAttribute(attr.name, attr.value);
        }
        // there are invalid characters for certain barcode types
        try { JsBarcode(svg).init() } catch (e) { console.log(e) }
    }

    connectedCallback() {
        this.#updateBarcode()
    }

    attributeChangedCallback(attrName, oldVal, newVal) {
        console.log("attributeChangedCallback", this, attrName, oldVal, newVal)
        this.#updateBarcode()
    }
}

window.customElements.define('flex-barcode', FlexBarcode);
