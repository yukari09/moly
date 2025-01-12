import {
    SetFeatureImage, PostDatetimePicker, 
    InputValueUpdater, TagsTagify, Editor} from "./hooks/post.js"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.SetFeatureImage = SetFeatureImage
Hooks.PostDatetimePicker = PostDatetimePicker
Hooks.InputValueUpdater = InputValueUpdater
Hooks.TagsTagify = TagsTagify
Hooks.Editor = Editor

export default Hooks
