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
import Hooks from "./hooks"
import Uploaders from "./uploaders"
import { Validators, countWords } from "./form-validate"
import Tagify from '@yaireo/tagify'


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

  if (validator != "undefined" && typeof Validators[validator] === "function") {
    let function_var = [event.target.value]
    if (params) {
      function_var = function_var.concat(params)
    }

    if(error_msg != "undefined"){
      function_var.push(error_msg)
    }

    const this_el_id = event.target.getAttribute("id")
    const validateResult = Validators[validator](...function_var)
    const elHelper = document.querySelector(`#${this_el_id}-helper`)
    const elError = document.querySelector(`#${this_el_id}-error`)
    const elErrorIcon = document.querySelector(`.${this_el_id}-icon`)

    const normalClass = event.target.dataset.normalClass
    const errorClass = event.target.dataset.errorClass

    if (validateResult !== true) {
      if (elError) {
        elError.textContent = validateResult;
        elError.classList.remove("hidden");
      }
      if (elHelper) {
        elHelper.classList.add("hidden");
      }
      event.target.setAttribute("data-validate", "0")
      if(normalClass && errorClass){
        let nc = normalClass.split(" ")
        let ec = errorClass.split(" ")
        event.target.classList.remove(...nc)
        event.target.classList.add(...ec)
      }
      if(elErrorIcon) elErrorIcon.classList.remove("hidden")
    } else {
      if (elError) {
        elError.textContent = "";
        elError.classList.add("hidden");
      }
      if (elHelper) {
        elHelper.classList.remove("hidden");
      }
      event.target.setAttribute("data-validate", "1")
      if(normalClass && errorClass){
        let nc = normalClass.split(" ")
        let ec = errorClass.split(" ")
        event.target.classList.remove(...ec)
        event.target.classList.add(...nc)
      }
      if(elErrorIcon) elErrorIcon.classList.add("hidden")
    }
  }
})

window.addEventListener("phx:validate-and-exec", async(event) => {
  if(event.target == window && event.detail.form_name){
    const formElements = document.querySelectorAll(`[name^="${event.detail.form_name}"]`)
    let dataInputDispatch = Array.from(formElements)
    .filter(el => {
      return  el.dataset.inputDispatch
    })
    dataInputDispatch.forEach(el => {
      const exec_event = new CustomEvent("app:validate-and-exec", {
        bubbles: true
      })
      el.dispatchEvent(exec_event)
    })
  }
})

window.addEventListener("app:validate-and-exec", async(event) => {
  if(event.target.dataset != undefined && event.target.dataset.inputDispatch != undefined){
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
  prefix = prefix ? prefix[0].split("_")[0] : event.target.dataset.formName

  if(prefix){
    const formElements = document.querySelectorAll(`[data-input-dispatch]`)

    let validated = Array.from(formElements)
    .filter(el => {
      return el.dataset.validate == "1"
    })

    const submit_btn = document.querySelector(`#${prefix}_submit`)

    if(formElements.length == validated.length){
      submit_btn.removeAttribute("disabled")
    }else{
      submit_btn.setAttribute("disabled", "disabled")
    }
  }
})

window.addEventListener("phx:TagsTagify", async(event) => {
  let el = event.detail.id === undefined 
  ? event.target 
  : document.querySelector(`${event.detail.id}`) || event.target;

  if (el.tagify !== undefined) {
    el.tagify.destroy();
  }

  let config = el.config === undefined 
    ? { whitelist: [], dropdown: { enabled: 0 } } 
    : JSON.parse(el.dataset.config);

  el.tagify = new Tagify(el, config);

})

window.addEventListener("phx:blank_link", event => {
  console.log(event)
  if (event.detail.url != undefined) window.open(event.detail.url, "_blank")
})

//Admin

window.addEventListener("app:disabledFormElement", (event) => {
  //disabled this form elements like input, select, checkbox, etc
  const form = event.target
  if (form) {
    const elements = form.querySelectorAll('input, select, textarea, button')
    elements.forEach(element => {
      element.disabled = true
    })
    setTimeout(() => {
      elements.forEach(element => {
        element.disabled = false
      })
    }, 2000)
  }
})

window.addEventListener("app:historyback", (event) => {event.target.tagName === "IFRAME"? event.target.contentWindow.history.back() : history.back()})

window.addEventListener("app:saveLocalStorage", ({detail}) => {
  localStorage.setItem(detail.key, btoa(detail.value))
})

window.addEventListener("app:recoverConnection", (event) => {
  const value = localStorage.getItem(event.detail.key)
  if (value) {
    localStorage.removeItem(event.detail.key)
    liveSocket.execJS(event.target, `[["exec",{"attr":"${atob(value)}"}]]`)
  }
})

window.addEventListener("app:addOverlayOnDragOver", (event) => {
  const overlay = document.createElement('div');
  overlay.style.cssText = 'position:absolute;inset:0;background:rgba(0,0,0,0.5);z-index:1000;pointer-events:none;';
  let isOverlayAdded = false;

  event.target.addEventListener('dragenter', (e) => {
    e.preventDefault();
    if (!isOverlayAdded) {
      event.target.style.position = 'relative';
      event.target.appendChild(overlay);
      isOverlayAdded = true;
    }
  });

  event.target.addEventListener('dragleave', (e) => {
    if (!e.relatedTarget || !event.target.contains(e.relatedTarget)) {
      if (isOverlayAdded) {
        event.target.removeChild(overlay);
        event.target.style.position = '';
        isOverlayAdded = false;
      }
    }
  });

  event.target.addEventListener('drop', (e) => {
    e.preventDefault();
    if (isOverlayAdded) {
      event.target.removeChild(overlay);
      event.target.style.position = '';
      isOverlayAdded = false;
    }
    liveSocket.execJS(event.target, `[["exec",{"attr":"phx-drop-target"}]]`);
  });
});

//add a listener to the window to submit the form
window.addEventListener("app:click-el", (event) => {
  if (event.target) {
    event.target.click();
  }
});
 

//----Start Admin Media Page Script----//
const mediaDataArrtribute = "data-media-id"
const mediaDataSelector = `[${mediaDataArrtribute}]`
const dataSelectedCounterSelector = "[data-selected-counter]"

const mediaActionsdisabledClass = ["opacity-50", "pointer-events-none"]
const mediaWrapRingClass = ["ring-2", "ring-gray-900", "ring-offset-2", "ring-offset-gray-100"]

const selectAllLinkSelector = "[data-action-link='select-all']"
const deselectAllLinkSelector = "[data-action-link='deselect-all']"
const deleteSelectedLinkSelector = "[data-action-link='delete-selected']"

window.addEventListener("media:actions:deleteSelected", (event) => {
    const el = document.querySelectorAll(`.${mediaWrapRingClass.join(".")}`)
    let elValues = []
    el.forEach(sigleEl => {
      elValues.push(sigleEl.getAttribute(mediaDataArrtribute))
    })

    const encodedJS = `[["push",{"value":{"data-id":"${elValues.join(",")}"},"event":"media:delete:selected"}]]`;
    liveSocket.execJS(event.target, encodedJS)
})

window.addEventListener("media:actions:count", (event) => {
    let currentSelectedMediaCount = selectedMediaCount()
    event.target.innerHTML = currentSelectedMediaCount
    updateStatus()
})

window.addEventListener("media:click", (event) => {
    mediaWrapRingClass.forEach(className => {
        event.target.classList.toggle(className)
    })
    setSelectedStyle(event.target, "toggle")
    updateStatus()
})

window.addEventListener("media:clickSingle", (event) => {
  document.querySelectorAll(event.detail.items).forEach(el => {
    mediaWrapRingClass.forEach(className => {
      el.classList.remove(className)
    })
  })
  mediaWrapRingClass.forEach(className => {
    event.target.classList.add(className)
  })
  const encodedJS = `[["push",{"value":{"id":"${event.target.dataset.mediaId}"},"event":"media:broadcast:selected"}]]`;
  liveSocket.execJS(event.target, encodedJS)
  setSelectedStyle(event.target, "toggle")
  updateStatus()
})


window.addEventListener("actions:selectAll:click", (event) => {
    document.querySelectorAll(mediaDataSelector).forEach(el => {
      el.classList.add(...mediaWrapRingClass)
      setSelectedStyle(el, "add")
    })
    updateStatus()
})

window.addEventListener("actions:deselectAll:click", (event) => {
    document.querySelectorAll(mediaDataSelector).forEach(el => {
      el.classList.remove(...mediaWrapRingClass)
      setSelectedStyle(el, "remove")
    })
    updateStatus()
})

window.addEventListener("phx:actions:updateStatus", (event) => {
  updateStatus()
})

const updateStatus = () => {
  let currentSelectedMediaCount = selectedMediaCount()

  let selectAllLink = document.querySelector(selectAllLinkSelector)
  let deselectAllLink = document.querySelector(deselectAllLinkSelector)
  let deleteSelectedLink = document.querySelector(deleteSelectedLinkSelector)

  if(selectAllLink && deselectAllLink && deleteSelectedLink){
    if (currentSelectedMediaCount > 0) {
      [deselectAllLink, deleteSelectedLink].forEach(link => {enableActions(link)})
    }else{
      [deleteSelectedLink, deselectAllLink].forEach(link => {disableActions(link)})
    }
    
    if(document.querySelectorAll(mediaDataSelector).length === currentSelectedMediaCount){
      disableActions(selectAllLink)
    }else{
      enableActions(selectAllLink)
    }
  
    document.querySelector(dataSelectedCounterSelector).innerHTML = currentSelectedMediaCount
  }

}

const setSelectedStyle = (el, classListFunName = "add") => {
    const leId = el.getAttribute("id")
    const overlayElement = document.querySelector(`#${leId}-overlay`)
    const checkElement = document.querySelector(`#${leId}-check`)

    if (overlayElement) {
        if(classListFunName === "add"){
            overlayElement.classList.add("!block")
        }else if(classListFunName === "remove"){
            overlayElement.classList.remove("!block")
        }else if(classListFunName === "toggle"){
            overlayElement.classList.toggle("!block")
        }
    }
    if (checkElement) {
      if(classListFunName === "add"){
        checkElement.classList.remove("opacity-0")
        checkElement.classList.add("opacity-75")
      }else if(classListFunName === "remove"){
        checkElement.classList.remove("opacity-75")
        checkElement.classList.add("opacity-0")
      }else if(classListFunName === "toggle"){
        checkElement.classList.toggle("opacity-75")
        checkElement.classList.toggle("opacity-0")
      }
    }
}

const disableActions = (el) => {
  el.setAttribute("disabled", "disabled")
  el.classList.add(...mediaActionsdisabledClass)
}

const enableActions = (el) => {
  el.removeAttribute("disabled")
  el.classList.remove(...mediaActionsdisabledClass)
}

const selectedMediaCount = () => {
    const selectedMediaSelector = `.${mediaWrapRingClass.join(".")}`
    return document.querySelectorAll(selectedMediaSelector).length
}
//----End Admin Media Page Script----//