import Sparkline from "sparklines"
import { formatHex } from 'culori'

export default {
    // https://github.com/mariusGundersen/sparkline
    // https://github.com/mariusGundersen/sparkline/blob/909da5007d1c46a35b17a4911dbfb40dc0f8ca3b/source/sparkline.js#L40
    mounted() {
        // JSON.parse returns object and push method is not found
        const data = Array.from(JSON.parse(this.el.dataset.set))
        const maxlen = parseInt(this.el.dataset.maxlen)
        const sindex = parseInt(this.el.dataset.index)
        const dotRadius = parseInt(this.el.dataset.dotRadius) || 2.5
        const styles = window.getComputedStyle(this.el)
        const width = parseInt(styles.width)
        const height = parseInt(styles.height)
        const lineColor = this.el.dataset.lineColor || formatHex(styles.color)
        const fillBelow = this.el.dataset.fillBelow || false
        const endColor = this.el.dataset.endColor || lineColor
        const minValue = this.el.dataset.minValue
        const maxValue = this.el.dataset.maxValue
        const opts = { width, height, lineColor, endColor, dotRadius, fillBelow, minValue, maxValue }
        // console.log(opts)
        const spark = new Sparkline(this.el, opts)
        this.handleEvent("spark:add", ({ index, chunk }) => {
            if (index != sindex) return;
            data.push(...chunk)
            while (data.length > maxlen) data.shift()
            spark.draw(data)
        })
        spark.draw(data)
    },
}