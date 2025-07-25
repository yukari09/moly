import Table from '@editorjs/table'
import CodeTool from '@editorjs/code'
import Embed from '@editorjs/embed'
import EditorJS from '@editorjs/editorjs'
import Header from "@editorjs/header"
import ImageTool from '@editorjs/image'
import List from '@editorjs/list'
import Quote from '@editorjs/quote'
import flatpickr from "flatpickr"
import { DateTime } from "luxon"
import Tagify from '@yaireo/tagify'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

const get_document_el = (key) => {
  return document.querySelector(`[data-id="${key}"]`);
}

const convert_to_camel = (str) => {
  return str.replace(/-([a-z])/g, (match, p1) => p1.toUpperCase());
}

const get_el_by_data_ids = (ids) => {
  return ids.reduce((acc, attr) => {
    acc[convert_to_camel(attr)] = get_document_el(attr);
    return acc
  }, {})
}

const disabled_el = (el) => {
  el.classList.add("pointer-events-none", "opacity-50")
  el.setAttribute("disabled", true)
}

const enabled_el = (el) => {
  el.classList.remove("pointer-events-none", "opacity-50")
  el.removeAttribute("disabled")
}


export const Resize = {
  // resize() {
  //     this.el.style.height = 'auto'
  //     this.el.style.height = this.el.scrollHeight + 'px'
  // },
  mounted(){
    this.resize = () => {
      this.el.style.height = 'auto'
      this.el.style.height = this.el.scrollHeight + 'px'
    }
    this.el.addEventListener('input', this.resize)
    this.resize()
  },
  updated() {
    this.el.addEventListener('input', this.resize)
    this.resize()
  }
}

export const FormChangeListener = {
  mounted() {
    const formElements = document.querySelectorAll('[name^="form"]');

    formElements.forEach(element => {
      element.dataset.prevValue = element.value;

      const observer = new MutationObserver(() => {
        if (element.dataset.prevValue !== element.value) {
          window.dispatchEvent(new CustomEvent('re_set_btn'));
          element.dataset.prevValue = element.value; 
        }
      });

      observer.observe(element, {
        attributes: true,
        attributeFilter: ['value']
      });

      element._mutationObserver = observer;
    });
  },

  destroyed() {
    const formElements = this.el.querySelectorAll('[name^="form"]');
    formElements.forEach(element => {
      const observer = element._mutationObserver;
      if (observer) {
        observer.disconnect();
      }
    });
  }
};


export const SetFeatureImage = {
  injection(iframe) {
    iframe.onload = () => {
      const { modal, cancelButton } = this.document_el();
      cancelButton.addEventListener('click', () => {
        this.liveSocket.execJS(modal, `[["exec",{"attr":"phx-remove"}]]`);
      })
      const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
      this.bindClickImageSelecte(iframeDoc);
      const observer = new MutationObserver(() => this.bindClickImageSelecte(iframeDoc));
      this.bindClickEvent()
      observer.observe(iframeDoc.body, { childList: true, subtree: true });
    }
    this.bindClickEvent()
  },

  document_el() {
    const attrs = [
      "confirm-button", "input-meta-value", "input-meta-key", 
      "image", "image-container", "set-image-button", 
      "modal", "remove-image-button", "cancel-button",
      'meta-value-input', 'meta-key-input',
    ]
    return get_el_by_data_ids(attrs)
  },

  mounted() {
    this.injection(this.el);
  },

  toggleElement(element, isVisible) {element.classList.toggle('hidden', !isVisible)},

  toggleButton(button, isEnabled) {
    button.disabled = !isEnabled;
    button.classList.toggle('pointer-events-none', !isEnabled);
    button.classList.toggle('opacity-50', !isEnabled);
  },

  toggleInput(input, isEnabled) {
    if(isEnabled){
      input.removeAttribute("disabled")
    }else{
      input.value=null
      input.setAttribute("disabled", "disabled")
    }
  },

  bindClickImageSelecte(iframeDoc){
    const mediaElements = iframeDoc.querySelectorAll('[data-media-id]');
    const {confirmButton, metaValueInput, image, metaKeyInput} = this.document_el();

    mediaElements.forEach((el) => {
      if (!el.hasAttribute('data-click-processed')) {
        el.addEventListener('click', () => {
          const classNames = ["ring-2", "ring-gray-900", "ring-offset-2", "ring-offset-gray-100"];
          mediaElements.forEach((otherEl) => otherEl.classList.remove(...classNames));
          el.classList.add(...classNames);

          confirmButton.classList.remove("pointer-events-none", "opacity-50");
          confirmButton.removeAttribute("disabled");

          metaValueInput.value = el.getAttribute('data-media-id');
          metaKeyInput.value = "thumbnail_id"
          image.setAttribute('src', el.getAttribute('data-media-url'));
        })
        el.setAttribute('data-click-processed', 'true');
      }
    })

  },

  bindClickEvent() {
    const {
      confirmButton, metaValueInput, metaKeyInput,
      imageContainer, setImageButton, modal, removeImageButton
    } = this.document_el();


    const confirmEvent = () => {
      this.toggleInput(metaValueInput, true);
      this.toggleInput(metaKeyInput, true);
      this.toggleElement(imageContainer, true);
      this.toggleElement(setImageButton, false);
      this.toggleButton(confirmButton, false);
      liveSocket.execJS(modal, `[["exec",{"attr":"phx-remove"}]]`);
    };

    const removeEvent = () => {
      this.toggleInput(metaValueInput, false);
      this.toggleInput(metaKeyInput, false);
      this.toggleElement(imageContainer, false);
      this.toggleElement(setImageButton, true);
    };

    [confirmButton, removeImageButton].forEach(button => {
      button.addEventListener('click', button === confirmButton ? confirmEvent : removeEvent);
    })
  }
};


export const PostDatetimePicker = {
  document_el() {
    return get_el_by_data_ids(['post-date-input', 'post-date-immediately', 'post-date-schedule'])
  },

  mounted() {
    const {postDateImmediately, postDateSchedule, postDateInput} = this.document_el()
    let utc_now = this.el.value;
    if(utc_now == ""){
      utc_now = DateTime.now().setZone('utc').toISO();
      postDateInput.value = utc_now; //replace
    }else{
      utc_now = DateTime.fromISO(utc_now, { zone: 'utc' }).setZone('local').toJSDate();
      postDateSchedule.innerHTML = DateTime.fromJSDate(utc_now).setZone('local').toLocaleString(DateTime.DATETIME_MED)
    }
    flatpickr(this.el, {
      enableTime: true,
      time_24hr: true,
      minDate: "today",
      dateFormat: "Y/m/d H:i",
      defaultDate: utc_now,
      onReady: function(selectedDates, dateStr, instance) {
        instance.calendarContainer.style.marginTop = "12px";
      },
      onChange: (selected_date, dateStr, instance) => {
        postDateInput.value = DateTime.fromJSDate(selected_date[0]).setZone('utc').toISO(); //replace
        postDateImmediately.classList.add("hidden");
        postDateSchedule.classList.remove("hidden");
        postDateSchedule.innerHTML = DateTime.fromJSDate(selected_date[0]).setZone('local').toLocaleString(DateTime.DATETIME_MED);
        window.dispatchEvent(new CustomEvent('re_set_btn'))
      }
    });
  }
}


export const InputValueUpdater = {
  document_el() {
    return get_el_by_data_ids(['post-name-dropdown', 'post-slug-label', 'post-slug-text', 'post-slug-input', 'post-slug-guid', 'post-slug-menu', "temporary-el", "post-post-name-oi"])
  },

  reset_dropdown(){
    const {postSlugLabel, postSlugMenu, temporaryEl} = this.document_el()

    const newPostSlugMenu = postSlugMenu.cloneNode(true);
    temporaryEl.appendChild(newPostSlugMenu);
    postSlugMenu.remove();

    const newPostSlugLabel = postSlugLabel.cloneNode(true);
    postSlugLabel.parentNode.replaceChild(newPostSlugLabel,postSlugLabel);

    const rect = newPostSlugLabel.parentNode.getBoundingClientRect();

    const windowWidth = window.innerWidth || document.documentElement.clientWidth;
    const scrollX = window.scrollX || document.documentElement.scrollLeft;
    const distanceFromRight = windowWidth - (rect.right + scrollX);

    newPostSlugMenu.parentNode.style.right = `${distanceFromRight}px`;
    newPostSlugMenu.parentNode.style.top = `${rect.height + rect.top}px`;
    newPostSlugMenu.parentNode.style.zIndex = `9999`;
    newPostSlugMenu.parentNode.style.position = `absolute`;
    newPostSlugMenu.parentNode.classList.remove("hidden");
  },

  input_value_change(){
    const {postSlugInput, postSlugGuid, postSlugText, postSlugLabel, postPostNameOi} = this.document_el()

    reset_value = (value) => {
      postSlugInput.value = value;
      postSlugLabel.innerHTML = value;
      postSlugGuid.value = `${postSlugInput.dataset.host}${value}`;
      postSlugText.innerHTML = `${postSlugInput.dataset.host}${value}`;
      postPostNameOi.value = value
    }

    postSlugInput.addEventListener('input', (event) => {
      const value = event.target.value;
      reset_value(value)
    })

    postSlugInput.addEventListener('blur', (event) => {
      const value = event.target.value;
      if(value.length < 8){
        reset_value(postSlugInput.dataset.default)
      }else{
        reset_value(value)
        postSlugInput.setAttribute("default", value)
      }
    })
    
  },

  mounted() {
    this.reset_dropdown()
    this.input_value_change()
  }
}

export const TagsTagify = {
  tagify(el){
    const targetContainer = document.querySelector(el.dataset.targetContainer)

    let tagify = new Tagify(el, {
      whitelist: [],  
      dropdown: {
        enabled: 0  
      }
    });

    tagify.on('add', (e) => {
      const namePrefix = el.dataset.targetName
      if(e.detail.data.__tagId){
        const index = targetContainer.childElementCount / 2

        const termNameInput = document.createElement('input');
        termNameInput.type = 'hidden';
        termNameInput.name = `${namePrefix}[${index}][name]`;
        termNameInput.value = e.detail.data.value;
        targetContainer.appendChild(termNameInput);

        const taxonomyInput = document.createElement('input');
        taxonomyInput.type = 'hidden';
        taxonomyInput.name = `${namePrefix}[${index}][term_taxonomy][][taxonomy]`;
        taxonomyInput.value = "post_tag";
        targetContainer.appendChild(taxonomyInput);
        window.dispatchEvent(new CustomEvent('re_set_btn'))
      }
    });

    tagify.on('remove', (e) => {
      // const namePrefix = this.el.dataset.targetName
      const inputs = targetContainer.querySelectorAll(`[data-value="${e.detail.data.value}"]`)
      inputs.forEach(input => {
        // if (input.value === e.detail.data.value || input.value === "post_tag") {
          targetContainer.removeChild(input)
        // }
      })
      window.dispatchEvent(new CustomEvent('re_set_btn'))
    });
    return tagify
  },
  mounted() {
    this.tagify(this.el)
  },
  updated() {
    this.tagify(this.el)
  }
};


export const Editor = {
  document_el() {
    return get_el_by_data_ids(["undo-button", "redo-button", "save-draft", "clear-editor", "publish-button", "post-title"])
  },

  re_set_btn() {
    const {undoButton, redoButton, saveDraft, clearEditor, publishButton, postTitle} = this.document_el()

    if(this.undoStack.length === 0) disabled_el(undoButton)
    if(this.undoStack.length > 0) enabled_el(undoButton)
    if(this.redoStack.length === 0) disabled_el(redoButton)
    if(this.redoStack.length > 0) enabled_el(redoButton)

    if(postTitle.value.length > 0 && this.currentState.blocks.length > 0){
      enabled_el(saveDraft)
      enabled_el(publishButton)
    }else{
      disabled_el(saveDraft)
      disabled_el(publishButton)
    }
    if(this.currentState.blocks.length > 0) enabled_el(clearEditor)
    if(this.currentState.blocks.length === 0) disabled_el(clearEditor)
  },

  setState(newState) {
    if (this.currentState !== null) {
      this.undoStack.push(this.currentState)
    }
    this.currentState = newState
    this.redoStack = []
    // this.re_set_btn()
  },

  undo() {
    if (this.undoStack.length === 0) {
      return;
    }
    this.redoStack.push(this.currentState) 
    this.currentState = this.undoStack.pop()
    this.editor.render(this.currentState)
    // this.re_set_btn()
    this.targetInput.value = JSON.stringify(this.currentState)
  },

  redo() {
    if (this.redoStack.length === 0) {
      return;
    }
    this.undoStack.push(this.currentState)
    this.currentState = this.redoStack.pop()
    this.editor.render(this.currentState)
    // this.re_set_btn()
    this.targetInput.value = JSON.stringify(this.currentState)
  },
 

  mounted() {

    this.undoStack = []
    this.redoStack = []
    
    this.targetInput = document.querySelector(`#${this.el.dataset.targetId}`)

    const empty_data = {time: Date.now(),blocks: []}
    const initialContent = this.targetInput.value == ""? empty_data: JSON.parse(this.targetInput.value)

    this.currentState = initialContent

    this.editor = new EditorJS({
      holder: this.el,
      code: CodeTool,
      placeholder: this.el.dataset.placeholder || 'Type text or paste a link',
      tools: {
        table: Table,
        embed: Embed,
        code: CodeTool,
        header: {
          class: Header,
          inlineToolbar: true
        },
        image: {
          class: ImageTool,
          config: {
            additionalRequestHeaders: {
              "x-csrf-token": csrfToken
            },
            endpoints: {
              byFile: '/upload-file', // Your backend file uploader endpoint
              byUrl: '/fetch-url', // Your endpoint that provides uploading by Url
            }
          }
        },
        list: {
          class: List,
          inlineToolbar: true,
          config: {
            defaultStyle: 'unordered'
          },
        },
        quote: {
          class: Quote,
          inlineToolbar: true,
          config: {
            quotePlaceholder: 'Enter a quote',
            captionPlaceholder: 'Quote\'s author'
          },
        },
        // image: {
        //   class: ImageTool,
        //   config: {
        //     endpoints: {
        //       byFile: '/upload-image', // Your backend file uploader endpoint
        //       byUrl: '/fetch-url', // Your endpoint that provides uploading by Url
        //     },
        //     additionalRequestHeaders: {
        //       "x-csrf-token": csrfToken
        //     }
        //   }
        // }
      },
      data: initialContent,
      onChange:  (api, event) => {
        api.saver.save().then(outputData => {
          this.targetInput.value = JSON.stringify(outputData);
          this.setState(outputData);
          this.re_set_btn()
        })
      }
    })

    window.addEventListener('undo', _ => {this.undo()})
    window.addEventListener('redo', _ => {this.redo()})
    window.addEventListener('re_set_btn', _ => {this.re_set_btn()})
    window.addEventListener('clear_editor', _ => {
      this.targetInput.value=""
      this.editor.render(empty_data)
      this.undoStack = []
      this.redoStack = []
      this.currentState = empty_data
      // this.re_set_btn()
    })
  },

  updated() {
    this.mounted()
  }
}

export const SelectAll = {
  mounted() {
    this.initializeSelectAll();
  },
  
  updated() {
    this.initializeSelectAll();
  },
  
  initializeSelectAll() {
    this.setupEventDelegation();
    this.updateSelectAllState();
  },
  
  setupEventDelegation() {
    if (this.boundSelectAllHandler) {
      this.el.removeEventListener('change', this.boundSelectAllHandler);
    }
    if (this.boundTargetHandler) {
      document.removeEventListener('change', this.boundTargetHandler);
    }
    
    this.boundSelectAllHandler = (e) => {
      this.handleSelectAllChange(e.target.checked);
    };
    this.el.addEventListener('change', this.boundSelectAllHandler);
    
    this.boundTargetHandler = (e) => {
      if (e.target.matches && e.target.matches(this.el.dataset.target)) {
        setTimeout(() => {
          this.updateSelectAllState();
        }, 0);
      }
    };
    document.addEventListener('change', this.boundTargetHandler);
  },
  
  handleSelectAllChange(isChecked) {
    const targetCheckboxes = document.querySelectorAll(this.el.dataset.target);
    
    targetCheckboxes.forEach(checkbox => {
      if (checkbox.checked !== isChecked) {
        checkbox.checked = isChecked;
        
        const changeEvent = new Event('change', { bubbles: true });
        checkbox.dispatchEvent(changeEvent);
        
        if (checkbox.hasAttribute('phx-click')) {
          const clickEvent = new Event('click', { bubbles: true });
          checkbox.dispatchEvent(clickEvent);
        }
      }
    });
  },
  
  updateSelectAllState() {
    const targetCheckboxes = document.querySelectorAll(this.el.dataset.target);
    
    if (targetCheckboxes.length === 0) {
      this.el.checked = false;
      this.el.indeterminate = false;
      return;
    }
    
    const checkedCount = Array.from(targetCheckboxes).filter(cb => cb.checked).length;
    const totalCount = targetCheckboxes.length;
    const selectedActionBtn = document.querySelector('[data-action-id="action-dropmenu"] button')

    if (checkedCount === 0) {
      this.el.checked = false;
      this.el.indeterminate = false;
      selectedActionBtn.setAttribute("disabled", "disabled")
    } else if (checkedCount === totalCount) {
      this.el.checked = true;
      this.el.indeterminate = false;
      selectedActionBtn.removeAttribute("disabled")
    } else {
      this.el.checked = false;
      this.el.indeterminate = true;
      selectedActionBtn.removeAttribute("disabled")
    }
  },
  
  destroyed() {
    if (this.boundSelectAllHandler) {
      this.el.removeEventListener('change', this.boundSelectAllHandler);
    }
    if (this.boundTargetHandler) {
      document.removeEventListener('change', this.boundTargetHandler);
    }
  }
};