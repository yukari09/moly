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
    
    // Load saved title from localStorage
    const savedTitle = localStorage.getItem('post-title')
    if (savedTitle) {
      this.el.value = savedTitle
      this.resize()
    }
    
    // Save title to localStorage on input
    this.el.addEventListener('input', (e) => {
      localStorage.setItem('post-title', e.target.value)
      this.resize()
      
      // Also update the hidden input if it exists
      const hiddenInput = document.querySelector(`input[name="${this.el.id}"]`)
      if (hiddenInput) {
        hiddenInput.value = e.target.value
        hiddenInput.dispatchEvent(new Event('change', { bubbles: true }))
      }
    })
    
    // Handle window resize
    window.addEventListener('resize', this.resize)
    
    // Handle paste events
    this.el.addEventListener('paste', () => {
      // Use setTimeout to ensure content is pasted before resizing
      setTimeout(this.resize, 0)
    })

    // Clear title when editor is cleared
    window.addEventListener('app:clearEditor', () => {
      this.el.value = ''
      localStorage.removeItem('post-title')
      this.resize()
      
      // Also update the hidden input if it exists
      const hiddenInput = document.querySelector(`input[name="${this.el.id}"]`)
      if (hiddenInput) {
        hiddenInput.value = ''
        hiddenInput.dispatchEvent(new Event('change', { bubbles: true }))
      }
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
    const savedTitle = localStorage.getItem('post-title')
    const initialContent = this.el.dataset.initialContent

    // Initialize undo/redo stacks
    this.undoStack = []
    this.redoStack = []

    console.log('Initializing editor with:', {
      savedContent,
      initialContent
    })

    if (savedContent) {
      try {
        const parsedContent = JSON.parse(savedContent)
        // Only use saved content if it has blocks
        if (parsedContent.blocks && parsedContent.blocks.length > 0) {
          initialData = parsedContent
          this.hasEditorContent = true
          console.log('Using saved content:', initialData)
        } else if (initialContent) {
          initialData = JSON.parse(initialContent)
          this.hasEditorContent = initialData.blocks && initialData.blocks.length > 0
          localStorage.setItem('editorjs-content', initialContent)
          console.log('Using initial content because saved content is empty:', initialData)
        }
      } catch (error) {
        console.error('Failed to parse saved content:', error)
      }
    } else if (initialContent) {
      try {
        initialData = JSON.parse(initialContent)
        this.hasEditorContent = initialData.blocks && initialData.blocks.length > 0
        // Save initial content to localStorage
        localStorage.setItem('editorjs-content', initialContent)
        console.log('Using initial content:', initialData)
      } catch (error) {
        console.error('Failed to parse initial content:', error)
      }
    }

    // Function to update button states
    this.updateButtonStates = () => {
      const titleInput = document.querySelector('#post_title')
      const hasTitle = titleInput && titleInput.value.trim() !== ''
      const hasEditorContent = this.hasEditorContent

      console.log('Updating button states:', { hasTitle, hasEditorContent })

      // Save draft button - 需要 editor 和 title 都有內容
      const saveDraftBtn = document.querySelector('[data-action="save-draft"]')
      if (saveDraftBtn) {
        if (hasTitle && hasEditorContent) {
          saveDraftBtn.classList.remove('text-gray-500', 'pointer-events-none')
          saveDraftBtn.classList.add('text-gray-700')
        } else {
          saveDraftBtn.classList.remove('text-gray-700')
          saveDraftBtn.classList.add('text-gray-500', 'pointer-events-none')
        }
      }

      // Clear editor button - 只要 editor 或 title 有內容就可以
      const clearEditorBtn = document.querySelector('[data-action="clear-editor"]')
      if (clearEditorBtn) {
        if (hasTitle || hasEditorContent) {
          clearEditorBtn.classList.remove('text-gray-500', 'pointer-events-none')
          clearEditorBtn.classList.add('text-gray-700')
        } else {
          clearEditorBtn.classList.remove('text-gray-700')
          clearEditorBtn.classList.add('text-gray-500', 'pointer-events-none')
        }
      }

      // Publish button - 需要 editor 和 title 都有內容
      const publishBtn = document.querySelector('[data-action="publish"]')
      if (publishBtn) {
        if (hasTitle && hasEditorContent) {
          publishBtn.classList.remove('pointer-events-none', 'opacity-50')
        } else {
          publishBtn.classList.add('pointer-events-none', 'opacity-50')
        }
      }

      // Update undo/redo button states
      const undoButton = document.querySelector('[data-editor-action="undo"]')
      const redoButton = document.querySelector('[data-editor-action="redo"]')
      
      if (undoButton) {
        if (this.undoStack.length > 0) {
          undoButton.removeAttribute('disabled')
        } else {
          undoButton.setAttribute('disabled', '')
        }
      }
      
      if (redoButton) {
        if (this.redoStack.length > 0) {
          redoButton.removeAttribute('disabled')
        } else {
          redoButton.setAttribute('disabled', '')
        }
      }
    }

    const editor = new EditorJS({
      holder: this.el,
      placeholder: this.el.dataset.placeholder || 'Type text or paste a link',
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
          }

          // Store previous state for undo
          const previousState = localStorage.getItem('editorjs-content')
          if (previousState && previousState !== JSON.stringify(outputData)) {
            this.undoStack.push(previousState)
            this.redoStack.length = 0 // Clear redo stack when new changes are made
          }
          localStorage.setItem('editorjs-content', JSON.stringify(outputData))

          // Update hasEditorContent flag and button states
          this.hasEditorContent = outputData.blocks && outputData.blocks.length > 0 && 
            outputData.blocks.some(block => {
              if (block.type === 'header') {
                return block.data && block.data.text && block.data.text.trim() !== ''
              } else if (block.type === 'quote') {
                return (block.data && block.data.text && block.data.text.trim() !== '') ||
                       (block.data && block.data.caption && block.data.caption.trim() !== '')
              } else if (block.type === 'list') {
                return block.data && block.data.items && block.data.items.some(item => item.trim() !== '')
              }
              return false
            })
          this.updateButtonStates()

          // Dispatch change event
          window.dispatchEvent(new CustomEvent('editorjs:change', {
            detail: { previousState, newState: JSON.stringify(outputData) }
          }))
        })
      }
    })

    this._editor = editor

    // Clear editor handler
    window.addEventListener('app:clearEditor', () => {
      // Store current state for undo before clearing
      editor.save().then((currentData) => {
        const currentState = JSON.stringify(currentData)
        if (currentState && currentData.blocks && currentData.blocks.length > 0) {
          this.undoStack.push(currentState)
          this.redoStack.length = 0
          this.updateButtonStates()
        }

        // Clear editor content
        this._editor.clear()
        
        // Clear title
        const titleInput = document.querySelector('#post_title')
        if (titleInput) {
          titleInput.value = ''
          // Trigger input event to update button states
          titleInput.dispatchEvent(new Event('input'))
        }

        // Clear localStorage
        localStorage.removeItem('editorjs-content')
        localStorage.removeItem('post-title')

        // Clear hidden input
        const contentEl = document.querySelector(`#${this.el.dataset.content}`)
        if (contentEl) {
          contentEl.value = JSON.stringify({ blocks: [] })
        }

        // Reset hasEditorContent flag
        this.hasEditorContent = false
        this.updateButtonStates()
      })
    })

    // Undo handler
    window.addEventListener('app:editorUndo', () => {
      if (this.undoStack.length > 0) {
        const previousState = this.undoStack.pop()
        const currentState = localStorage.getItem('editorjs-content')
        
        // Save current state to redo stack
        if (currentState) {
          this.redoStack.push(currentState)
        }

        // Restore previous state
        const previousData = JSON.parse(previousState)
        this._editor.render(previousData)
        localStorage.setItem('editorjs-content', previousState)

        // Update content input
        const contentEl = document.querySelector(`#${this.el.dataset.content}`)
        if (contentEl) {
          contentEl.value = previousState
        }

        // Update hasEditorContent flag
        this.hasEditorContent = previousData.blocks && previousData.blocks.length > 0
        this.updateButtonStates()
      }
    })

    // Redo handler
    window.addEventListener('app:editorRedo', () => {
      if (this.redoStack.length > 0) {
        const nextState = this.redoStack.pop()
        const currentState = localStorage.getItem('editorjs-content')
        
        // Save current state to undo stack
        if (currentState) {
          this.undoStack.push(currentState)
        }

        // Restore next state
        const nextData = JSON.parse(nextState)
        this._editor.render(nextData)
        localStorage.setItem('editorjs-content', nextState)

        // Update content input
        const contentEl = document.querySelector(`#${this.el.dataset.content}`)
        if (contentEl) {
          contentEl.value = nextState
        }

        // Update hasEditorContent flag
        this.hasEditorContent = nextData.blocks && nextData.blocks.length > 0
        this.updateButtonStates()
      }
    })

    // Enable undo/redo keyboard shortcuts
    this.el.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'z') {
        if (e.shiftKey) {
          // Ctrl/Cmd + Shift + Z (Redo)
          window.dispatchEvent(new Event('app:editorRedo'))
        } else {
          // Ctrl/Cmd + Z (Undo)
          window.dispatchEvent(new Event('app:editorUndo'))
        }
      }
    })

    // Initial button states
    this.updateButtonStates()
  },

  destroyed() {
    const titleInput = document.querySelector('#post_title')
    if (titleInput) {
      titleInput.removeEventListener('input', this.updateButtonStates)
    }
    if (this._editor) {
      this._editor.destroy()
    }
  }
};

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
        const immediatelyEl = document.querySelector(this.el.dataset.immediately)
        const calendarEl = document.querySelector(this.el.dataset.calendar)
        if (calendarEl) {
          const utcDateTime = DateTime.fromISO(this.el.value, { zone: "utc" })
          const localDateTime = utcDateTime.setZone(DateTime.local().zoneName).toLocaleString(DateTime.DATETIME_MED) 
          calendarEl.innerText = localDateTime
          immediatelyEl.classList.add("hidden")
        }
      }    
    });
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

Hooks.IframeMediaSelector = {
  mounted() {
    const iframe = this.el;
    const modalId = this.el.dataset.modalId;
    const mediaWrapRingClass = ["ring-2", "ring-gray-900", "ring-offset-2", "ring-offset-gray-100"];
    
    const updateMediaItemStyle = (mediaItem, isSelected) => {
      const overlayId = mediaItem.getAttribute('id') + '-overlay';
      const checkId = mediaItem.getAttribute('id') + '-check';
      const overlay = document.getElementById(overlayId);
      const check = document.getElementById(checkId);
      
      mediaWrapRingClass.forEach(className => {
        isSelected ? mediaItem.classList.add(className) : mediaItem.classList.remove(className);
      });
      
      if (overlay) {
        isSelected ? overlay.classList.add('!block') : overlay.classList.remove('!block');
      }
      if (check) {
        check.classList.toggle('opacity-0', !isSelected);
        check.classList.toggle('opacity-75', isSelected);
      }
    };

    const handleMediaSelection = (mediaId, mediaUrl) => {
      const confirmButton = document.querySelector('#modal-comfirm-button');
      if (!confirmButton) return;

      // 啟用確認按鈕
      confirmButton.classList.remove('pointer-events-none', 'opacity-50');
      confirmButton.removeAttribute('disabled');
      confirmButton.setAttribute('phx-value-media-id', mediaId);
      
      // 為確認按鈕添加點擊事件
      confirmButton.addEventListener('click', () => {
        // 更新隱藏輸入框的值
        const metaValueInput = document.querySelector('#thumbnail_id_meta_value');
        if (metaValueInput) {
          metaValueInput.value = mediaId;
        }
        
        // 更新預覽圖片
        const featuredImageContainer = document.querySelector('#featured-image-container');
        const previewImage = featuredImageContainer?.querySelector('img');
        if (previewImage && mediaUrl) {
          previewImage.src = mediaUrl;
          featuredImageContainer.classList.remove('hidden');
        }

        // 隱藏 Set featured image 按鈕
        const setFeaturedButton = Array.from(document.querySelectorAll('button'))
          .find(button => button.textContent.trim() === 'Set featured image');
        if (setFeaturedButton) {
          setFeaturedButton.classList.add('hidden');
        }

        // 禁用確認按鈕
        confirmButton.setAttribute('disabled', 'disabled');
        confirmButton.classList.add('pointer-events-none', 'opacity-50');

        // 關閉模態框
        this.liveSocket.execJS(document.getElementById(modalId), `[["exec",{"attr":"phx-remove"}]]`);
      }, { once: true });
    };
    
    const handleIframeLoad = () => {
      try {
        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
        if (!iframeDoc) {
          throw new Error('無法訪問 iframe 文檔');
        }
        
        const script = document.createElement('script');
        script.textContent = `
          const mediaWrapRingClass = ${JSON.stringify(mediaWrapRingClass)};
          const updateMediaItemStyle = ${updateMediaItemStyle.toString()};
          
          document.addEventListener('click', function(e) {
            const mediaItem = e.target.closest('.media-list-item');
            if (!mediaItem) return;
            
            // 清除其他項目的選中狀態
            document.querySelectorAll('.media-list-item').forEach(el => {
              updateMediaItemStyle(el, false);
            });
            
            // 設置當前項目的選中狀態
            updateMediaItemStyle(mediaItem, true);
            
            window.parent.postMessage({
              type: 'mediaSelected',
              mediaId: mediaItem.getAttribute('data-media-id'),
              mediaUrl: mediaItem.getAttribute('data-media-url')
            }, '*');
          });
        `;
        iframeDoc.body.appendChild(script);
      } catch (error) {
        console.error('初始化媒體選擇器時發生錯誤:', error.message);
      }
    };

    // 處理來自 iframe 的消息
    const handleMessage = (event) => {
      if (!event.data || event.data.type !== 'mediaSelected') return;
      handleMediaSelection(event.data.mediaId, event.data.mediaUrl);
    };

    iframe.addEventListener('load', handleIframeLoad);
    window.addEventListener('message', handleMessage);

    // 清理事件監聽器
    this.destroy = () => {
      iframe.removeEventListener('load', handleIframeLoad);
      window.removeEventListener('message', handleMessage);
    };
  }
}

Hooks.InputValueUpdater = {
  mounted() {
    this.updateTargets = this.updateTargets.bind(this);
    this.el.addEventListener('blur', this.updateTargets);
    this.el.dataset.original = this.el.value;
  },

  updateTargets() {
    const value = this.el.value.trim();
    const targetSelector = this.el.dataset.target;
    const targetEls = document.querySelectorAll(targetSelector);
    const originalValue = this.el.dataset.original;

    let newValue = value;
    if (value === '/') {
      newValue = originalValue;
    } else if (!value.startsWith('/')) {
      newValue = value.length > 0 ? '/' + value : originalValue;
    }

    this.el.value = newValue;
    this.el.dataset.original = newValue;
    targetEls.forEach(targetEl => {
      if (targetEl) targetEl.innerText = newValue;
    });
  },

  destroyed() {
    this.el.removeEventListener('blur', this.updateTargets);
  }
};

 
export default Hooks
