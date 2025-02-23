import {
    SetFeatureImage, PostDatetimePicker, 
    InputValueUpdater, TagsTagify, Editor,
    FormChangeListener, Resize} from "./hooks/post.js"

import Quill, { Delta } from 'quill';

// let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.SetFeatureImage = SetFeatureImage
Hooks.PostDatetimePicker = PostDatetimePicker
Hooks.InputValueUpdater = InputValueUpdater
Hooks.TagsTagify = TagsTagify
Hooks.Editor = Editor
Hooks.FormChangeListener = FormChangeListener
Hooks.Resize = Resize


Hooks.DescriptionEditor = {
  init_editor(el) {
    const config = JSON.parse(el.dataset.config)
    const tartget_input = document.querySelector(el.dataset.target)

    const quillInstance = new Quill(
        el,config
    )
    quillInstance.clipboard.addMatcher(Node.ELEMENT_NODE, function(node, delta) {
      if (node.style) {
        node.style.backgroundColor = '';
        node.style.color = '';
      }
      if (node.tagName === 'IMG') {
          return new Delta()
      }
      if (node.tagName === 'A') {
          const textContent = node.textContent;
          return new Delta().insert(textContent);
      }
      delta.forEach(e => {
        if(e.attributes){
          e.attributes.color = '';
          e.attributes.background = '';
        }
      });
      return delta;
    })
    quillInstance.on('text-change', function(delta, oldDelta, source) {
      let editorContent = quillInstance.root.innerHTML
      tartget_input.value = editorContent
      let event = new Event('input', {
        bubbles: true,  
        cancelable: true  
      })
      tartget_input.dispatchEvent(event)
    })
    return quillInstance
  },
  mounted(){
    this.init_editor(this.el)
  },
  updated(){
    const tartget_input = document.querySelector(this.el.dataset.target)
    this.init_editor(this.el).root.innerHTML = tartget_input.value;
  }
}
 

export default Hooks


