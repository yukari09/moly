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

// Allows to execute JS commands from the server
window.addEventListener("phx:js-exec", ({detail}) => {
  document.querySelectorAll(detail.to).forEach(el => {
    liveSocket.execJS(el, el.getAttribute(detail.attr))
  })
})

 
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
});


window.addEventListener("app:historyback", (_) => {history.back()})
window.addEventListener("app:contentWindowHistoryback", (event) => {event.target.contentWindow.history.back()})


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
 