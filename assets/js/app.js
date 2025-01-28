// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import Hooks from "./hooks-client"
import Uploaders from "./uploaders"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 3000,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
  uploaders: Uploaders,
  dom: {
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to)
      }
    }
  }
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket


function countWords(text) {
  /**
   * 計算文本中不同語言的字數，支持多語言混合。
   *
   * @param {string} text - 輸入的文本。
   * @returns {object} 各類字符的字數統計。
   */

  // 定義正則表達式匹配不同類型的字符
  const patterns = {
      chinese: /[\u4e00-\u9fff]/g, // 中文字符
      japanese: /[\u3040-\u30ff\u31f0-\u31ff\uff66-\uff9f]/g, // 日文假名
      korean: /[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]/g, // 韓文字母
      english: /\b[a-zA-Z]+\b/g, // 英文字母（單詞）
      russian: /\b[\u0400-\u04FF]+\b/g, // 俄文字母（單詞）
      digits: /\b[0-9]+\b/g, // 數字（整體匹配）
      symbols: /[!@#$%^&*(),.?\":{}|<>\[\]\\/;']/g, // 符號
      others: /[^\s\w\u4e00-\u9fff\u3040-\u30ff\u31f0-\u31ff\uff66-\uff9f\uac00-\ud7af\u1100-\u11ff\u3130-\u318f\u0400-\u04FF]/g // 其他字符
  };

  // 初始化統計結果
  const counts = Object.fromEntries(Object.keys(patterns).map(key => [key, 0]));

  // 計算每一類字符的數量
  for (const [key, pattern] of Object.entries(patterns)) {
      const matches = text.match(pattern);
      if (matches) {
          counts[key] = matches.length; // 確保所有類型按匹配次數計算
      }
  }

  // 計算總字數（不包括符號和其他非語言字符）
  counts.total = Object.entries(counts)
      .filter(([key]) => key !== "symbols" && key !== "others") // 排除符號和其他非語言字符
      .reduce((sum, [_, count]) => sum + count, 0);

  return counts.total;
}


window.addEventListener("phx:show-modal", async (event) => {  
  let el = document.querySelector(event.detail.el)
  el.showModal()
})

window.addEventListener("app:count_word", async (event) => {
  const text = event.target.value.trim()
  event.target.setAttribute("data-count-word", countWords(text))
})

//fill attr value to other el textContent
//<input 
// id="input1" 
// attr="value" 
// phx-change={
//   JS.dispatch(
//     "app:fill_text_with_attribute", 
//      detail: %{to_el: "span2", from_attr: "attr"})
// }>123</span>
//<span id="span2"></span>
window.addEventListener("app:fill_text_with_attribute", async (event) => {
  const from_el = event.target
  const to_el = document.querySelector(`${event.detail.to_el}`)
  const from_attr = event.detail.from_attr

  if(from_el, to_el, from_attr){ to_el.textContent =  from_el.getAttribute(from_attr)}
})


window.addEventListener("app:input-validate", async(event) => {
  const {validator, params, error_msg} = event.detail

  if (validator != "undefined" && typeof validators[validator] === "function") {
    let function_var = [event.target.value]
    if (params) {
      function_var = function_var.concat(params)
    }

    if(error_msg != "undefined"){
      function_var.push(error_msg)
    }

    const this_el_id = event.target.getAttribute("id")
    const validateResult = validators[validator](...function_var)
    const elHelper = document.querySelector(`#${this_el_id}-helper`)
    const elError = document.querySelector(`#${this_el_id}-error`)

    if (validateResult !== true) {
      if (elError) {
        elError.textContent = validateResult;
        elError.classList.remove("hidden");
      }
      if (elHelper) {
        elHelper.classList.add("hidden");
      }
      event.target.setAttribute("data-validate", "0")
    } else {
      if (elError) {
        elError.textContent = "";
        elError.classList.add("hidden");
      }
      if (elHelper) {
        elHelper.classList.remove("hidden");
      }
      event.target.setAttribute("data-validate", "1")
    }
  }
})

window.addEventListener("app:validate-and-exec", async(event) => {
  if(event.target.dataset.inputDispatch != "undefined"){
    JSON.parse(event.target.dataset.inputDispatch).forEach(e => {
      const event_name = e[0]
      const data_name = `data-${event_name.replace(":","-")}`
      let event_detail = {}
      if(e.length == 2) event_detail = e[1].detail
      const exec_event = new CustomEvent(event_name, {
        detail: event_detail,
        bubbles: true
      })
      event.target.dispatchEvent(exec_event)
      event.target.setAttribute(data_name, 'true')
    })
  }

  const name = event.target.getAttribute("name")
  let prefix =  name.match(/^([^\[]+)/)
  prefix = prefix ? prefix[0] : null
  if(prefix){
    const formElements = document.querySelectorAll(`[name^="${prefix}"]`)

    let dataInputDispatch = Array.from(formElements)
    .filter(el => {
      return  el.dataset.inputDispatch
    })

    let validated = Array.from(formElements)
    .filter(el => {
      return el.dataset.validate == "1"
    })

    const submit_btn = document.querySelector(`#${prefix}_submit`)

    console.log([dataInputDispatch.length , validated.length])

    if(dataInputDispatch.length == validated.length){
      submit_btn.removeAttribute("disabled")
      submit_btn.classList.remove("btn-disabled")
    }else{
      submit_btn.setAttribute("disabled", "disabled")
      submit_btn.classList.add("btn-disabled")
    }
  }
})


const validators = {
  required(value, msg = "This field is required.") {
    if (value !== null && value !== undefined && value.toString().trim() !== "") {
      return true;
    }
    return msg;
  },

  length(value, min, max, msg) {
    const len = value? countWords(value) : 0
    if (len >= min && len <= max) {
      return true;
    }
    return msg || `The length must be between ${min} and ${max} words.`;
  },

  range(value, min, max, msg) {
    const num = parseFloat(value);
    if (!isNaN(num) && num >= min && num <= max) {
      return true;
    }
    return msg || `The value must be between ${min} and ${max}.`;
  },

  isNumber(value, msg = "This field must be a valid number.") {
    return !isNaN(parseFloat(value)) && isFinite(value) ? true : msg;
  },

  isEmail(value, msg = "This field must be a valid email address.") {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(value) ? true : msg;
  },

  isURL(value, msg = "This field must be a valid URL.") {
    try {
      new URL(value);
      return true;
    } catch {
      return msg;
    }
  },

  matches(value, regex, msg = "The value does not match the required format.") {
    return regex.test(value) ? true : msg;
  },

  isDate(value, msg = "This field must be a valid date (YYYY-MM-DD).") {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    return dateRegex.test(value) && !isNaN(new Date(value).getTime()) ? true : msg;
  },

  isBoolean(value, msg = "This field must be true or false.") {
    return typeof value === "boolean" ? true : msg;
  },

  isInteger(value, msg = "This field must be an integer.") {
    return Number.isInteger(Number(value)) ? true : msg;
  },

  isUpperCase(value, msg = "This field must be in uppercase.") {
    return value === value.toUpperCase() ? true : msg;
  },

  isLowerCase(value, msg = "This field must be in lowercase.") {
    return value === value.toLowerCase() ? true : msg;
  },

  inList(value, list, msg = "This field must be one of the allowed values.") {
    return list.includes(value) ? true : msg;
  },

  isPhoneNumber(value, msg = "This field must be a valid phone number.") {
    const phoneRegex = /^\+?[1-9]\d{1,14}$/; // E.164 標準
    return phoneRegex.test(value) ? true : msg;
  },

  isJSON(value, msg = "This field must be a valid JSON string.") {
    try {
      JSON.parse(value);
      return true;
    } catch {
      return msg;
    }
  }
}

