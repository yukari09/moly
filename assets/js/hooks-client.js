import Quill, { Delta } from 'quill';
import {Resize, TagsTagify} from "./hooks/post.js"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")


let Hooks = {}

Hooks.Resize = Resize
Hooks.TagsTagify = TagsTagify

Hooks.Editor = {
  init_editor(el, config, tartget_input) {
        const quill = new Quill(
          el,config
      )
      quill.clipboard.addMatcher(Node.ELEMENT_NODE, function(node, delta) {
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
      quill.on('text-change', function(delta, oldDelta, source) {
        let editorContent = quill.root.innerHTML
        tartget_input.value = editorContent
      })
  },
  mounted(){
    const config = JSON.parse(this.el.dataset.config)
    const tartget_input = document.querySelector(this.el.dataset.target)
    this.init_editor(this.el, config, tartget_input)
  },
  updated(){
    const config = JSON.parse(this.el.dataset.config)
    const tartget_input = document.querySelector(this.el.dataset.target)
    this.init_editor(this.el, config, tartget_input)
  }
}

export default Hooks
