import {Resize} from "./hooks/post.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.Resize = Resize


export default Hooks
