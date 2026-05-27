import QRCode from "qrcode"

// https://www.npmjs.com/package/qrcode
class FlexQR extends HTMLElement {

    constructor() {
        super()
        this.attachShadow({ mode: "open" })
    }

    // https://www.npmjs.com/package/qrcode#qr-code-options
    static get observedAttributes() {
        return [
            "data-text",
            "data-width",
            "data-margin",
            "data-version",
            "data-maskpattern",
            "data-errorcorrectionlevel"
        ]
    }

    // scale not changing anything
    #rebuildElement() {
        this.shadowRoot.innerHTML = "<canvas/>"
        const canvas = this.shadowRoot.firstChild
        const text = this.getAttribute("data-text")
        const width = this.getAttribute("data-width")
        const margin = this.getAttribute("data-margin")
        const version = this.getAttribute("data-version")
        const maskPattern = this.getAttribute("data-maskpattern")
        const errorCorrectionLevel = this.getAttribute("data-errorcorrectionlevel")
        const options = { width, margin, version, maskPattern, errorCorrectionLevel }
        try { QRCode.toCanvas(canvas, text, options) } catch (e) { console.log(e) }
    }

    connectedCallback() {
        this.#rebuildElement()
    }

    attributeChangedCallback(attrName, oldVal, newVal) {
        this.#rebuildElement()
    }
}

window.customElements.define("flex-qr", FlexQR);
