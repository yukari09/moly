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

window.addEventListener("phx:show-modal", async (event) => {  
  let el = document.querySelector(event.detail.el)
  el.showModal()
})


const text_length = (text) => {
  if (!text) return 0; 

  const isChineseOrJapanese = /[\u4e00-\u9fa5\u3040-\u30ff\u31f0-\u31ff\u4e00-\u9fff]/.test(text);
  const isPureEnglish = /^[a-zA-Z]+$/.test(text); 

  if (isChineseOrJapanese) {
    return text.length; 
  }

  if (isPureEnglish) {
    return text.length; 
  }

  return text.trim().split(/\s+/).length;
}


window.addEventListener("app:count_word", async (event) => {
  const text = event.target.value.trim()
  event.target.setAttribute("data-count-word", text_length(text))
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

// HTML
/*
<label>
  <input phx-change={JS.dispatch("app:form_enabled_button")} 
    id="input-id"
    data-validator="length" 
    data-validator-params="1,2,3" 
    data-error-msg="Must be between 1 and 3 characters." 
  />
  <span id="input-id-helper">Input your name</span>
  <span id="input-id-error" class="hidden"></span>
</label>
*/

window.addEventListener("app:validate_input", async (event) => {
  const { validator, validatorParams, errorMsg } = event.target.dataset;
  const this_el_id = event.target.getAttribute("id")
  if(!this_el_id){
    return;
  }
  if (validator != "undefined" && typeof validators[validator] === "function") {
    let function_var = [event.target.value];
    if (validatorParams) {
      function_var = function_var.concat(validatorParams.split(","))
    }

    if(errorMsg){
      function_var.push(errorMsg)
    }

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

window.addEventListener("app:enable_btn_from_form_inputs", event => {
  const target_btn_selector = event.target.dataset.targetBtn
  const els = event.target.dataset.targetEls
  if(els && target_btn_selector){
    const target_btn = document.querySelector(target_btn_selector)
    const all_el_selector = els.split(",")
    let validated_status = []
    all_el_selector.forEach(el_selector => {
      if(document.querySelector(el_selector).dataset.validate === "1") validated_status.push("1")
    })
    if(all_el_selector.length == validated_status.length){
      target_btn.classList.remove("btn-disabled")    
      target_btn.removeAttribute("disabled")
    }else{
      target_btn.classList.add("btn-disabled")    
      target_btn.setAttribute("disabled","true")
    }
  }
})

window.addEventListener("app:click_next_btn", event => {
  
})

const validators = {
  required(value, msg = "This field is required.") {
    if (value !== null && value !== undefined && value.toString().trim() !== "") {
      return true;
    }
    return msg;
  },

  length(value, min, max, msg) {
    const len = value? text_length(value) : 0
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

