/** @type {import('tailwindcss').Config} */

const plugin = require("tailwindcss/plugin")
const path = require("path")
const fs = require("fs")

module.exports = {
  content: [
    `../${path.basename(__dirname)}.exs`,
    "./js/**/*.js",
    "./**/*.exs",
    "./**/*.ex"
  ],
  plugins: [
    require("@tailwindcss/forms"),
    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "node_modules/heroicons")
      let values = {}
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
        ["-micro", "/16/solid"]
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach(file => {
          let name = path.basename(file, ".svg") + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      values["modbus-terminal"] = { name: "modbus-terminal", fullPath: "../static/menu/modbus-terminal.svg" }
      values["modbus-devices"] = { name: "modbus-devices", fullPath: "../static/menu/modbus-devices.svg" }
      values["export-serial"] = { name: "export-serial", fullPath: "../static/menu/export-serial.svg" }
      matchComponents({
        "hero": ({ name, fullPath }) => {
          let content = fs.readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
          let size = theme("spacing.6")
          if (name.endsWith("-mini")) {
            size = theme("spacing.5")
          } else if (name.endsWith("-micro")) {
            size = theme("spacing.4")
          }
          return {
            [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
            "-webkit-mask": `var(--hero-${name})`,
            "mask": `var(--hero-${name})`,
            "mask-repeat": "no-repeat",
            "background-color": "currentColor",
            "vertical-align": "middle",
            "display": "inline-block",
            "width": size,
            "height": size
          }
        }
      }, { values })
    })
  ]
}
