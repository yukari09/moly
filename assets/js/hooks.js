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

// Auto-resize textarea hook
Hooks.AutoResizeTextarea = {
  mounted() {
    this.resize = () => {
      this.el.style.height = 'auto'
      this.el.style.height = this.el.scrollHeight + 'px'
    }
    
    // Initial resize
    this.resize()
    
    // Resize on input
    this.el.addEventListener('input', this.resize)
    
    // Handle window resize
    window.addEventListener('resize', this.resize)
    
    // Handle paste events
    this.el.addEventListener('paste', () => {
      // Use setTimeout to ensure content is pasted before resizing
      setTimeout(this.resize, 0)
    })
  },
  
  updated() {
    this.resize()
  },
  
  destroyed() {
    this.el.removeEventListener('input', this.resize)
    window.removeEventListener('resize', this.resize)
  }
}

Hooks.Editor = {
  mounted() {
    // Get initial content first
    let initialData = {}
    const savedContent = localStorage.getItem('editorjs-content')
    const initialContent = this.el.dataset.initialContent

    if (savedContent) {
      try {
        initialData = JSON.parse(savedContent)
      } catch (error) {
        console.error('Failed to parse saved content:', error)
      }
    } else if (initialContent) {
      try {
        initialData = JSON.parse(initialContent)
        // Save initial content to localStorage
        localStorage.setItem('editorjs-content', initialContent)
      } catch (error) {
        console.error('Failed to parse initial content:', error)
      }
    }

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
      data: initialData,
      onChange: () => {
        editor.save().then((outputData) => {
          const contentEl = document.querySelector(`#${this.el.dataset.content}`)
          if (contentEl) {
            contentEl.value = JSON.stringify(outputData)
            contentEl.dispatchEvent(new Event('change', { bubbles: true }))
            
            // Save current state to localStorage and add to undo stack
            try {
              const previousState = localStorage.getItem('editorjs-content')
              localStorage.setItem('editorjs-content', JSON.stringify(outputData))
              
              // Create undo/redo command
              if (previousState) {
                const command = {
                  newState: JSON.stringify(outputData),
                  oldState: previousState
                }
                undoStack.push(command)
                // Clear redo stack when new changes are made
                redoStack.length = 0
                updateButtonStates()
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
        // Update the hidden input field with initial content
        const contentEl = document.querySelector(`#${this.el.dataset.content}`)
        if (contentEl && initialData.blocks && initialData.blocks.length > 0) {
          contentEl.value = JSON.stringify(initialData)
          contentEl.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }
    });

    // Clear editor handler
    window.addEventListener('app:clearEditor', () => {
      editor.save().then((currentData) => {
        const currentState = JSON.stringify(currentData)
        
        // Save the current state to undo stack before clearing
        if (currentState && currentData.blocks && currentData.blocks.length > 0) {
          const command = {
            newState: JSON.stringify({ blocks: [] }),
            oldState: currentState
          }
          undoStack.push(command)
          redoStack.length = 0
          updateButtonStates()
        }

        // Now clear the editor
        editor.clear().then(() => {
          // Clear the hidden input field as well
          const contentEl = document.querySelector(`#${this.el.dataset.content}`)
          if (contentEl) {
            contentEl.value = JSON.stringify({ blocks: [] })
            contentEl.dispatchEvent(new Event('change', { bubbles: true }))
          }
          // Clear localStorage
          localStorage.removeItem('editorjs-content')
        }).catch((error) => {
          console.error('Clearing failed: ', error)
        });
      });
    });

    // Undo/Redo stacks
    const undoStack = []
    const redoStack = []

    // Update button states
    const updateButtonStates = () => {
      const undoButton = document.querySelector('[data-editor-action="undo"]')
      const redoButton = document.querySelector('[data-editor-action="redo"]')
      
      if (undoButton) {
        if (undoStack.length > 0) {
          undoButton.removeAttribute('disabled')
        } else {
          undoButton.setAttribute('disabled', 'true')
        }
      }
      
      if (redoButton) {
        if (redoStack.length > 0) {
          redoButton.removeAttribute('disabled')
        } else {
          redoButton.setAttribute('disabled', 'true')
        }
      }
    }

    // Debounce function
    const debounce = (func, wait) => {
      let timeout
      return function executedFunction(...args) {
        const later = () => {
          clearTimeout(timeout)
          func(...args)
        }
        clearTimeout(timeout)
        timeout = setTimeout(later, wait)
      }
    }

    // Undo handler
    window.addEventListener('app:editorUndo', () => {
      const undoButton = document.querySelector('[data-editor-action="undo"]')
      if (undoButton && !undoButton.hasAttribute('disabled') && undoStack.length > 0) {
        const command = undoStack.pop()
        const oldData = JSON.parse(command.oldState)
        
        // Debounced render
        const debouncedRender = debounce(() => {
          editor.render(oldData).then(() => {
            localStorage.setItem('editorjs-content', command.oldState)
            
            // Update hidden input
            const contentEl = document.querySelector(`#${this.el.dataset.content}`)
            if (contentEl) {
              contentEl.value = command.oldState
              contentEl.dispatchEvent(new Event('change', { bubbles: true }))
            }
          })
        }, 100)

        debouncedRender()
        redoStack.push(command)
        updateButtonStates()
      }
    });

    // Redo handler
    window.addEventListener('app:editorRedo', () => {
      const redoButton = document.querySelector('[data-editor-action="redo"]')
      if (redoButton && !redoButton.hasAttribute('disabled') && redoStack.length > 0) {
        const command = redoStack.pop()
        const newData = JSON.parse(command.newState)
        
        // Debounced render
        const debouncedRender = debounce(() => {
          editor.render(newData).then(() => {
            localStorage.setItem('editorjs-content', command.newState)
            
            // Update hidden input
            const contentEl = document.querySelector(`#${this.el.dataset.content}`)
            if (contentEl) {
              contentEl.value = command.newState
              contentEl.dispatchEvent(new Event('change', { bubbles: true }))
            }
          })
        }, 100)

        debouncedRender()
        undoStack.push(command)
        updateButtonStates()
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

    // Initial button states
    updateButtonStates()
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
