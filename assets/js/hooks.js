import EditorJS from '@editorjs/editorjs'
import Header from "@editorjs/header"
import List from '@editorjs/list'
import Quote from '@editorjs/quote'
import LazyLoad from "vanilla-lazyload"
import flatpickr from "flatpickr"
import { DateTime } from "luxon"
import Tagify from '@yaireo/tagify'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}
Hooks.Editor = {
  mounted() {
    const editor = new EditorJS({
      holder: this.el,
      placeholder: this.el.dataset.placeholder,
      tools: {
        header: {
          class: Header,
          inlineToolbar: true
        },
        list: List,
        quote: {
          class: Quote,
          inlineToolbar: true,
          config: {
            quotePlaceholder: 'Enter a quote',
            captionPlaceholder: 'Quote\'s author'
          },
        },
      },
      data: {},
      onChange: () => {
        editor.save().then((outputData) => {
          const contentEl = document.querySelector(`#${this.el.dataset.content}`)
          if (contentEl) {
            contentEl.value = JSON.stringify(outputData)
            contentEl.dispatchEvent(new Event('change', { bubbles: true }))
            
            // Save current state to localStorage
            try {
              localStorage.setItem('editorjs-content', JSON.stringify(outputData))
              // Enable undo button after content change
              const undoButton = document.querySelector('[data-editor-action="undo"]')
              if (undoButton) {
                undoButton.removeAttribute('disabled')
              }
              // Disable redo button when new content is added
              const redoButton = document.querySelector('[data-editor-action="redo"]')
              if (redoButton) {
                redoButton.setAttribute('disabled', 'true')
              }
            } catch (error) {
              console.error('Failed to save to localStorage:', error)
            }
          }
        }).catch((error) => {
          console.error('Saving failed: ', error)
        });
      },
      onReady: () => {
        // Try to load saved content from localStorage first
        const savedContent = localStorage.getItem('editorjs-content')
        if (savedContent) {
          try {
            const parsedContent = JSON.parse(savedContent)
            editor.render(parsedContent)
            return
          } catch (error) {
            console.error('Failed to parse saved content:', error)
          }
        }

        // Fall back to initial content from data attribute
        const initialContent = this.el.dataset.initialContent
        if (initialContent) {
          try {
            const parsedContent = JSON.parse(initialContent)
            editor.render(parsedContent)
            
            // Save initial content to localStorage if it doesn't exist
            if (!localStorage.getItem('editorjs-content')) {
              localStorage.setItem('editorjs-content', initialContent)
            }

            // Update the hidden input field
            const contentEl = document.querySelector(`#${this.el.dataset.content}`)
            if (contentEl) {
              contentEl.value = initialContent
              contentEl.dispatchEvent(new Event('change', { bubbles: true }))
            }
          } catch (error) {
            console.error('Failed to parse initial content:', error)
          }
        }
      }
    });

    // Clear editor handler
    window.addEventListener('app:clearEditor', () => {
      editor.clear().then(() => {
        // Clear the hidden input field as well
        const contentEl = document.querySelector(`#${this.el.dataset.content}`)
        if (contentEl) {
          contentEl.value = JSON.stringify({ blocks: [] })
          contentEl.dispatchEvent(new Event('change', { bubbles: true }))
        }
        // Clear localStorage
        localStorage.removeItem('editorjs-content')
        // Disable both buttons
        const undoButton = document.querySelector('[data-editor-action="undo"]')
        const redoButton = document.querySelector('[data-editor-action="redo"]')
        if (undoButton) undoButton.setAttribute('disabled', 'true')
        if (redoButton) redoButton.setAttribute('disabled', 'true')
      }).catch((error) => {
        console.error('Clearing failed: ', error)
      });
    });

    // Undo handler
    window.addEventListener('app:editorUndo', () => {
      const undoButton = document.querySelector('[data-editor-action="undo"]')
      if (undoButton && !undoButton.hasAttribute('disabled')) {
        try {
          document.execCommand('undo')
          // Enable redo button after undo
          const redoButton = document.querySelector('[data-editor-action="redo"]')
          if (redoButton) {
            redoButton.removeAttribute('disabled')
          }
          // Check if we can still undo
          if (!document.queryCommandEnabled('undo')) {
            undoButton.setAttribute('disabled', 'true')
          }
        } catch (error) {
          console.error('Undo failed:', error)
        }
      }
    });

    // Redo handler
    window.addEventListener('app:editorRedo', () => {
      const redoButton = document.querySelector('[data-editor-action="redo"]')
      if (redoButton && !redoButton.hasAttribute('disabled')) {
        try {
          document.execCommand('redo')
          // Enable undo button after redo
          const undoButton = document.querySelector('[data-editor-action="undo"]')
          if (undoButton) {
            undoButton.removeAttribute('disabled')
          }
          // Check if we can still redo
          if (!document.queryCommandEnabled('redo')) {
            redoButton.setAttribute('disabled', 'true')
          }
        } catch (error) {
          console.error('Redo failed:', error)
        }
      }
    });

    this._editor = editor;

    // Enable undo/redo keyboard shortcuts
    this.el.addEventListener('keydown', (e) => {
      if (e.key === 'z' && (e.ctrlKey || e.metaKey)) {
        if (e.shiftKey) {
          // Ctrl/Cmd + Shift + Z = Redo
          e.preventDefault();
          this.el.dispatchEvent(new CustomEvent('app:editorRedo'));
        } else {
          // Ctrl/Cmd + Z = Undo
          e.preventDefault();
          this.el.dispatchEvent(new CustomEvent('app:editorUndo'));
        }
      } else if (e.key === 'y' && (e.ctrlKey || e.metaKey)) {
        // Ctrl/Cmd + Y = Redo (alternative)
        e.preventDefault();
        this.el.dispatchEvent(new CustomEvent('app:editorRedo'));
      }
    });

    // Initial button state
    const undoButton = document.querySelector('[data-editor-action="undo"]')
    const redoButton = document.querySelector('[data-editor-action="redo"]')
    if (undoButton) undoButton.setAttribute('disabled', 'true')
    if (redoButton) redoButton.setAttribute('disabled', 'true')
  },

  destroyed() {
    if (this._editor) {
      this._editor.destroy();
    }
  }
}

Hooks.lazyLoad = {
  mounted() {
    new LazyLoad({container: this.el})
  },
  updated() {
    new LazyLoad({container: this.el})
  }
}

Hooks.DatetimePicker = {
  mounted() {
    flatpickr(this.el, {
      enableTime: true,   
      time_24hr: true,          
      dateFormat: "Y-m-d H:i",
      readonlyInput: false,  
      minuteIncrement: 1,   
      onChange: (selectedDates, dateStr, instance) => {
        const datetime = DateTime.fromJSDate(selectedDates[0]).setZone("utc")
        this.el.value = datetime.toISO()
        const targetElement = document.querySelector(this.el.dataset.utcTarget)
        if (targetElement) {
          const utcDateTime = DateTime.fromISO(this.el.value, { zone: "utc" })
          const localDateTime = utcDateTime.setZone(DateTime.local().zoneName).toLocaleString(DateTime.DATETIME_MED) 
          targetElement.textContent = localDateTime
        }
      }    
    });
  }
}

Hooks.LocalizeDateTime = {
  mounted() {
    this.localizeText();
  },
  localizeText() {
    const utcText = this.el.innerText
    if (utcText) {
      const utcDateTime = DateTime.fromISO(utcText, { zone: "utc" });
      const localDateTime = utcDateTime.setZone(DateTime.local().zoneName).toLocaleString(DateTime.DATETIME_MED);
      this.el.innerText = localDateTime;
    }
  }
}

Hooks.BindInputToUrl = {
  mounted() {
    this.inputElement = document.querySelector(this.el.dataset.target);
    this.baseUrl = this.el.dataset.baseUrl;
    this.inputElement.addEventListener('input', () => this.bindValueToUrl(this.el));
  },
  
  updated() {
    this.inputElement = document.querySelector(this.el.dataset.target);
    this.baseUrl = this.el.dataset.baseUrl;
    this.inputElement.addEventListener('input', () => this.bindValueToUrl(this.el));
  },

  bindValueToUrl(el) {
    const value = this.inputElement.value.trim();
    let formattedValue = value
    if(!value.startsWith('/')){
      formattedValue = `/${value}`
    }
    this.inputElement.value = formattedValue
    el.innerText = `${this.baseUrl}${formattedValue}`
  }
}

Hooks.TagifyHook = {
  mounted() {
    let input = this.el;
    const targetContainer = document.querySelector(this.el.dataset.targetContainer)

    this.tagify = new Tagify(input, {
      whitelist: [],  
      dropdown: {
        enabled: 0  
      }
    });

    this.tagify.on('add', (e) => {
      console.log('Tag added:', e.detail.data)
      const namePrefix = this.el.dataset.targetName
      if(e.detail.data.__tagId){
        const taxonomyInput = document.createElement('input');
        taxonomyInput.type = 'hidden';
        taxonomyInput.name = `${namePrefix}[][taxonomy]`;
        taxonomyInput.value = "post_tag";
        targetContainer.appendChild(taxonomyInput);

        const termNameInput = document.createElement('input');
        termNameInput.type = 'hidden';
        termNameInput.name = `${namePrefix}[][name]`;
        termNameInput.value = e.detail.data.value;
        targetContainer.appendChild(termNameInput);
      }
    });

    this.tagify.on('remove', (e) => {
      const namePrefix = this.el.dataset.targetName
      const inputs = targetContainer.querySelectorAll(`input[name^="${namePrefix}"]`)
      inputs.forEach(input => {
        if (input.value === e.detail.data.value || input.value === "post_tag") {
          targetContainer.removeChild(input)
        }
      })
    });
  },

  destroyed() {
    this.tagify.destroy();
  }
};

export default Hooks
