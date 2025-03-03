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
 


Hooks.ScrollPagination = {
  mounted() {
    // 獲取DOM元素
    const container = this.el;
    const itemList = container.querySelector(".item-list");
    const prevBtn = container.querySelector(".prev");
    const nextBtn = container.querySelector(".next");

    // 計算尺寸和頁數
    let containerWidth = container.offsetWidth;
    let totalWidth = itemList.scrollWidth;
    let total_page = Math.ceil(totalWidth / containerWidth);
    let current_page = 1;
    let isAnimating = false;

    // 更新按鈕顯示狀態
    const updateButtons = () => {
      nextBtn.style.visibility = current_page < total_page ? "visible" : "hidden";
      prevBtn.style.visibility = current_page > 1 ? "visible" : "hidden";
    };

    // 計算下一頁的偏移量
    const calculateNextOffset = (currentPage, containerWidth, totalPages, totalWidth) => {
      let offset = currentPage * containerWidth;
      
      // 最後一頁可能不需要完整滾動
      if (currentPage + 1 === totalPages) {
        offset -= (containerWidth - totalWidth % containerWidth);
      }
      
      return -offset;
    };

    // 計算上一頁的偏移量
    const calculatePrevOffset = (currentPage, containerWidth) => {
      return -(currentPage - 2) * containerWidth;
    };

    // 滾動到指定位置，帶動畫效果
    const scrollWithAnimation = (targetOffset) => {
      if (isAnimating) return;
      isAnimating = true;
      
      const startOffset = parseInt(getComputedStyle(itemList).transform.split(',')[4]) || 0;
      const distance = targetOffset - startOffset;
      const duration = 500; // 動畫持續時間（毫秒）
      const startTime = performance.now();
      
      // 動畫函數
      const animate = (currentTime) => {
        const elapsedTime = currentTime - startTime;
        const progress = Math.min(elapsedTime / duration, 1);
        
        // 使用緩動函數使動畫更自然
        const easeOutCubic = 1 - Math.pow(1 - progress, 3);
        const currentOffset = startOffset + distance * easeOutCubic;
        
        itemList.style.transform = `translateX(${currentOffset}px)`;
        
        if (progress < 1) {
          requestAnimationFrame(animate);
        } else {
          isAnimating = false;
        }
      };
      
      requestAnimationFrame(animate);
    };

    // 處理滾動
    const scrollItems = (direction) => {
      let targetOffset;
      
      if (direction === "next" && current_page < total_page) {
        targetOffset = calculateNextOffset(current_page, containerWidth, total_page, totalWidth);
        current_page += 1;
      } else if (direction === "prev" && current_page > 1) {
        targetOffset = calculatePrevOffset(current_page, containerWidth);
        current_page -= 1;
      } else {
        return; // 無效的滾動方向或已到達邊界
      }
      
      scrollWithAnimation(targetOffset);
      updateButtons();
    };

    // 監聽按鈕點擊事件
    prevBtn.addEventListener("click", (e) => {
      e.preventDefault();
      scrollItems("prev");
    });

    nextBtn.addEventListener("click", (e) => {
      e.preventDefault();
      scrollItems("next");
    });

    // 處理窗口大小變化
    const handleResize = () => {
      // 重新計算尺寸
      containerWidth = container.offsetWidth;
      totalWidth = itemList.scrollWidth;
      total_page = Math.ceil(totalWidth / containerWidth);
      
      // 確保當前頁不超過總頁數
      current_page = Math.min(current_page, total_page);
      
      // 重新定位到當前頁
      const offset = calculatePrevOffset(current_page + 1, containerWidth);
      itemList.style.transform = `translateX(${offset}px)`;
      
      updateButtons();
    };
    
    window.addEventListener("resize", handleResize);
    this.handleResize = handleResize; // 保存引用以便在destroyed中移除

    // 初始化：檢查是否有活動項目需要滾動到視圖中
    const btnNavActive = itemList.querySelector('.btn-nav-active');
    if (btnNavActive) {
      const itemListRect = itemList.getBoundingClientRect();
      const btnNavActiveRect = btnNavActive.getBoundingClientRect();
      const distance = btnNavActiveRect.right - itemListRect.left;
      const translate = Math.ceil(distance / containerWidth);

      if (translate > 1) {
        const offset = calculateNextOffset(translate - 1, containerWidth, total_page, totalWidth);
        itemList.style.transform = `translateX(${offset}px)`;
        current_page = translate;
      }
    }

    // 初始化按鈕狀態
    updateButtons();
  },
  
  updated() {
    // 如果內容更新，重新計算並調整
    if (this.handleResize) {
      this.handleResize();
    }
  },
  
  destroyed() {
    // 清理事件監聽器
    if (this.handleResize) {
      window.removeEventListener("resize", this.handleResize);
    }
  }
};

export default Hooks


