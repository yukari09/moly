import EditorJS from '@editorjs/editorjs'
import Header from "@editorjs/header"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.Editor = {
  mounted() {
    const editor = new EditorJS({
      /**
       * Id of Element that should contain the Editor
       */
      holder : this.el,
      placeholder: this.el.dataset.placeholder,
      /**
       * Available Tools list.
       * Pass Tool's class or Settings object for each Tool you want to use
       */
      tools: {
        header: {
          class: Header,
          inlineToolbar : true
        },
        // ...
      },
    
      /**
       * Previously saved data that should be rendered
       */
      data: {}
    });
  }
}
export default Hooks
