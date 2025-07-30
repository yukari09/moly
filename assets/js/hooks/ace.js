// Ace.js LiveView Hook
// 使用方法：在你的 LiveView 模板中添加 phx-hook="AceEditor"

const AceEditor = {
  // 靜態方法：加載 Ace.js 腳本
  loadAce() {
    return new Promise((resolve, reject) => {
      // 檢查是否已經加載
      if (window.ace) {
        resolve();
        return;
      }

      // 檢查是否正在加載
      if (window.aceLoading) {
        window.aceLoading.then(resolve).catch(reject);
        return;
      }

      // CDN 備選方案
      const cdnUrls = [
        'https://cdnjs.cloudflare.com/ajax/libs/ace/1.32.6/ace.min.js',
        'https://cdn.jsdelivr.net/npm/ace-builds@1.32.6/src-min-noconflict/ace.js',
        'https://unpkg.com/ace-builds@1.32.6/src-min-noconflict/ace.js'
      ];

      const extensionUrls = [
        'https://cdnjs.cloudflare.com/ajax/libs/ace/1.32.6/ext-language_tools.min.js',
        'https://cdn.jsdelivr.net/npm/ace-builds@1.32.6/src-min-noconflict/ext-language_tools.js',
        'https://unpkg.com/ace-builds@1.32.6/src-min-noconflict/ext-language_tools.js'
      ];

      // 嘗試加載函數
      const tryLoadScript = (urls, index = 0) => {
        if (index >= urls.length) {
          throw new Error('All CDN sources failed to load');
        }

        return new Promise((scriptResolve, scriptReject) => {
          const script = document.createElement('script');
          script.src = urls[index];
          script.crossOrigin = 'anonymous';
          
          script.onload = scriptResolve;
          script.onerror = () => {
            console.warn(`Failed to load from ${urls[index]}, trying next CDN...`);
            tryLoadScript(urls, index + 1).then(scriptResolve).catch(scriptReject);
          };
          
          document.head.appendChild(script);
        });
      };

      // 開始加載
      window.aceLoading = new Promise((loadResolve, loadReject) => {
        tryLoadScript(cdnUrls).then(() => {
          // 加載擴展包
          return tryLoadScript(extensionUrls);
        }).then(() => {
          delete window.aceLoading;
          loadResolve();
        }).catch((error) => {
          delete window.aceLoading;
          loadReject(error);
        });
      });

      window.aceLoading.then(resolve).catch(reject);
    });
  },

  async mounted() {
    try {
      // 首先加載 Ace.js
      await this.loadAce();
    } catch (error) {
      console.error('Failed to load Ace.js:', error);
      this.el.innerHTML = '<div style="color: red; padding: 10px;">Failed to load Ace.js editor</div>';
      return;
    }
    // 顯示加載中狀態
    this.el.innerHTML = '<div style="padding: 10px; text-align: center; color: #666;">Loading Ace Editor...</div>';

    // 獲取配置參數
    const config = {
      theme: this.el.dataset.theme || "ace/theme/monokai",
      mode: this.el.dataset.mode || "ace/mode/javascript",
      fontSize: parseInt(this.el.dataset.fontSize) || 14,
      tabSize: parseInt(this.el.dataset.tabSize) || 2,
      wrap: this.el.dataset.wrap === "true",
      readOnly: this.el.dataset.readOnly === "true",
      showPrintMargin: this.el.dataset.showPrintMargin !== "false",
      highlightActiveLine: this.el.dataset.highlightActiveLine !== "false",
      enableBasicAutocompletion: this.el.dataset.enableAutocompletion !== "false",
      enableLiveAutocompletion: this.el.dataset.enableLiveAutocompletion === "true",
      enableSnippets: this.el.dataset.enableSnippets === "true",
      inputName: this.el.dataset.name // 表單字段名稱
    };

    // 創建隱藏的 input 字段用於表單提交
    if (config.inputName) {
      this.hiddenInput = document.createElement('input');
      this.hiddenInput.type = 'hidden';
      this.hiddenInput.name = config.inputName;
      this.hiddenInput.value = this.el.dataset.initialValue || "";
      
      // 將隱藏字段插入到編輯器元素之後
      this.el.parentNode.insertBefore(this.hiddenInput, this.el.nextSibling);
    }

    // 清空加載中的提示
    this.el.innerHTML = '';

    // 初始化 Ace 編輯器
    this.editor = ace.edit(this.el);
    this.editor.setTheme(config.theme);
    this.editor.session.setMode(config.mode);
    this.editor.setFontSize(config.fontSize);
    this.editor.session.setTabSize(config.tabSize);
    this.editor.session.setUseWrapMode(config.wrap);
    this.editor.setReadOnly(config.readOnly);
    this.editor.setShowPrintMargin(config.showPrintMargin);
    this.editor.setHighlightActiveLine(config.highlightActiveLine);

    // 設置自動完成
    this.editor.setOptions({
      enableBasicAutocompletion: config.enableBasicAutocompletion,
      enableLiveAutocompletion: config.enableLiveAutocompletion,
      enableSnippets: config.enableSnippets
    });

    // 設置初始內容
    const initialValue = this.el.dataset.initialValue || "";
    this.editor.setValue(initialValue, -1); // -1 表示移動光標到開頭

    // 防抖函數，避免過於頻繁的更新
    this.debounceTimer = null;
    const debounceDelay = parseInt(this.el.dataset.debounce) || 300;

    // 監聽內容變化並發送到 LiveView
    this.editor.on('change', () => {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = setTimeout(() => {
        const content = this.editor.getValue();
        
        // 更新隱藏字段的值
        if (this.hiddenInput) {
          this.hiddenInput.value = content;
        }
        
        this.pushEvent("ace_content_changed", { content: content });
      }, debounceDelay);
    });

    // 監聽光標位置變化
    this.editor.selection.on('changeCursor', () => {
      const cursor = this.editor.getCursorPosition();
      this.pushEvent("ace_cursor_changed", { 
        row: cursor.row, 
        column: cursor.column 
      });
    });

    // 監聽選擇變化
    this.editor.selection.on('changeSelection', () => {
      const range = this.editor.getSelectionRange();
      const selectedText = this.editor.getSelectedText();
      this.pushEvent("ace_selection_changed", {
        start: { row: range.start.row, column: range.start.column },
        end: { row: range.end.row, column: range.end.column },
        selectedText: selectedText
      });
    });
  },

  updated() {
    // 當 LiveView 更新時，檢查是否需要更新編輯器內容
    const newValue = this.el.dataset.value;
    if (newValue !== undefined && newValue !== this.editor.getValue()) {
      const cursorPosition = this.editor.getCursorPosition();
      this.editor.setValue(newValue, -1);
      this.editor.moveCursorToPosition(cursorPosition);
      
      // 同步更新隱藏字段
      if (this.hiddenInput) {
        this.hiddenInput.value = newValue;
      }
    }

    // 更新其他配置
    const newTheme = this.el.dataset.theme;
    if (newTheme && newTheme !== this.currentTheme) {
      this.editor.setTheme(newTheme);
      this.currentTheme = newTheme;
    }

    const newMode = this.el.dataset.mode;
    if (newMode && newMode !== this.currentMode) {
      this.editor.session.setMode(newMode);
      this.currentMode = newMode;
    }

    const newFontSize = parseInt(this.el.dataset.fontSize);
    if (newFontSize && newFontSize !== this.currentFontSize) {
      this.editor.setFontSize(newFontSize);
      this.currentFontSize = newFontSize;
    }
  },

  destroyed() {
    // 清理資源
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    if (this.editor) {
      this.editor.destroy();
    }
    // 清理隱藏字段
    if (this.hiddenInput && this.hiddenInput.parentNode) {
      this.hiddenInput.parentNode.removeChild(this.hiddenInput);
    }
  },

  // 處理來自 LiveView 的推送事件
  reconnected() {
    // 重新連接時可能需要重新同步狀態
    console.log("AceEditor reconnected");
  },

  disconnected() {
    // 斷開連接時的處理
    console.log("AceEditor disconnected");
  }
};

// 導出 Hook 以供 LiveView 使用
export default AceEditor;

// 如果你使用的是 CommonJS 或直接在 script 標籤中使用：
// window.AceEditor = AceEditor;

/* 
使用示例：

1. 在你的 app.js 中註冊 Hook：
import AceEditor from "./ace_editor_hook"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: { AceEditor },
  params: {_csrf_token: csrfToken}
})

2. 在 LiveView 模板中使用（在表單內）：
<.form for={@form} phx-submit="save">
  <div class="field">
    <.label for="code">Code</.label>
    <div id="code-editor" 
         phx-hook="AceEditor"
         data-name="post[code]"
         data-theme="ace/theme/monokai"
         data-mode="ace/mode/elixir"
         data-font-size="14"
         data-initial-value={@form[:code].value}
         data-debounce="300"
         style="height: 400px; width: 100%;">
    </div>
  </div>
  
  <.button type="submit">Save</.button>
</.form>

3. 在 LiveView 模組中處理表單提交：
def handle_event("save", %{"post" => post_params}, socket) do
  # post_params["code"] 會包含編輯器的內容
  case MyApp.Posts.create_post(post_params) do
    {:ok, post} ->
      {:noreply, 
        socket
        |> put_flash(:info, "Post created successfully")
        |> push_navigate(to: ~p"/posts/#{post}")}
    
    {:error, %Ecto.Changeset{} = changeset} ->
      {:noreply, assign(socket, form: to_form(changeset))}
  end
end

4. 或者使用 Phoenix.HTML.Form.inputs_for：
<.form for={@form} phx-submit="save">
  <.inputs_for :let={f} field={@form[:content]}>
    <div id="code-editor" 
         phx-hook="AceEditor"
         data-name={input_name(f, :code)}
         data-initial-value={input_value(f, :code)}
         style="height: 400px;">
    </div>
  </.inputs_for>
  
  <.button type="submit">Save</.button>
</.form>
def handle_event("ace_content_changed", %{"content" => content}, socket) do
  {:noreply, assign(socket, :code_content, content)}
end

def handle_event("ace_cursor_changed", %{"row" => row, "column" => col}, socket) do
  # 處理光標位置變化
  {:noreply, socket}
end

def handle_event("ace_selection_changed", params, socket) do
  # 處理選擇變化
  {:noreply, socket}
end

支持的語言模式：
- ace/mode/javascript
- ace/mode/elixir  
- ace/mode/python
- ace/mode/html
- ace/mode/css
- ace/mode/json
- ace/mode/sql
- ace/mode/markdown
等等...

支持的主題：
- ace/theme/monokai
- ace/theme/github
- ace/theme/tomorrow
- ace/theme/twilight
- ace/theme/solarized_dark
- ace/theme/solarized_light
等等...
*/