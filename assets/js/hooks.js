import {
    SetFeatureImage, PostDatetimePicker, 
    InputValueUpdater, TagsTagify, Editor,
    FormChangeListener, Resize} from "./hooks/post.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.SetFeatureImage = SetFeatureImage
Hooks.PostDatetimePicker = PostDatetimePicker
Hooks.InputValueUpdater = InputValueUpdater
Hooks.TagsTagify = TagsTagify
Hooks.Editor = Editor
Hooks.FormChangeListener = FormChangeListener
Hooks.Resize = Resize

export default Hooks
