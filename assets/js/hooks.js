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

export default Hooks
