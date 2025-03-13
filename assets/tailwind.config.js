// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")
// const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  important: ".moly-web",
  content: [
    "./js/**/*.js",
    // "../lib/moly_web.ex",
    "../lib/moly_web/**/*.*ex",
    "../lib/moly/utilities/*.*ex",
    "../deps/ash_authentication_phoenix/**/*.*ex",
    "../storybook/**/*.*exs",
  ],
  // daisyui: {
  //   themes: [
  //     {
  //       dark: {
  //         ...require("daisyui/src/theming/themes")["dark"],
  //       }
  //     },
  //     {
  //       light: {
  //         ...require("daisyui/src/theming/themes")["light"],
  //         primary: "#017802",
  //         "primary-content": "#ffffff",
  //         secondary: "#BED73B",
  //         accent: "#744C29",
  //       }
  //     }
  //   ]
  // },
  theme: {
    extend: {
      colors: {
        green: {
          50: '#e7f9e7',    // 很淺的綠色
          100: '#c0f0c0',    // 稍淺的綠色
          200: '#92e692',    // 淺綠色
          300: '#65db65',    // 較亮的綠色
          400: '#38d238',    // 中等淺綠色
          500: '#1ac11a',    // 中等綠色
          600: '#19a019',    // 稍深的綠色
          700: '#178c17',    // 深綠色
          800: '#017802',    // 設為 #017802，最深的綠色
          900: '#005a02',    // 更深的綠色，為了讓綠色更深   
        },
        primary: "#017802",
        "primary-content": "#ffffff",
        secondary: "#BED73B",
        accent: "#744C29",
      },
      fontFamily: {
        sans: [
          '"InterVariable", ui-sans-serif, system-ui, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol", "Noto Color Emoji"',         
          {
            fontFeatureSettings: '"cv02", "cv03", "cv04", "cv11"',
            fontVariationSettings: '"opsz" 32'
          }
        ],
        serif: ["ui-serif", "Georgia", "Cambria", "Times New Roman", "Times", "serif"],
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "Monaco", "Consolas", "Liberation Mono", "Courier New", "monospace"],
      },
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("tailwindcss-animate"),
    // require("@tailwindcss/forms"),
    // require('daisyui'),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    // 
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function({matchComponents, theme}) {
      let iconsDir = path.join(__dirname, "../deps/heroicons/optimized")
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
          values[name] = {name, fullPath: path.join(iconsDir, dir, file)}
        })
      })
      matchComponents({
        "hero": ({name, fullPath}) => {
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
      }, {values})
    })
  ]
}
