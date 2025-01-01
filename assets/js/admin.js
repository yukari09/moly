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