import {
    SetFeatureImage,
    PostDatetimePicker,
    InputValueUpdater,
    TagsTagify,
    Editor,
    FormChangeListener,
    Resize,
} from "./hooks/post.js";

import Quill, { Delta } from "quill";
import Splide from "@splidejs/splide";

// let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {};

Hooks.SetFeatureImage = SetFeatureImage;
Hooks.PostDatetimePicker = PostDatetimePicker;
Hooks.InputValueUpdater = InputValueUpdater;
Hooks.TagsTagify = TagsTagify;
Hooks.Editor = Editor;
Hooks.FormChangeListener = FormChangeListener;
Hooks.Resize = Resize;

Hooks.DescriptionEditor = {
    init_editor(el) {
        const config = JSON.parse(el.dataset.config);
        const tartget_input = document.querySelector(el.dataset.target);

        const quillInstance = new Quill(el, config);
        quillInstance.clipboard.addMatcher(
            Node.ELEMENT_NODE,
            function (node, delta) {
                if (node.style) {
                    node.style.backgroundColor = "";
                    node.style.color = "";
                }
                if (node.tagName === "IMG") {
                    return new Delta();
                }
                if (node.tagName === "A") {
                    const textContent = node.textContent;
                    return new Delta().insert(textContent);
                }
                delta.forEach((e) => {
                    if (e.attributes) {
                        e.attributes.color = "";
                        e.attributes.background = "";
                    }
                });
                return delta;
            },
        );
        quillInstance.on("text-change", function (delta, oldDelta, source) {
            let editorContent = quillInstance.root.innerHTML;
            tartget_input.value = editorContent;
            let event = new Event("input", {
                bubbles: true,
                cancelable: true,
            });
            tartget_input.dispatchEvent(event);
        });
        return quillInstance;
    },
    mounted() {
        this.init_editor(this.el);
    },
    updated() {
        const tartget_input = document.querySelector(this.el.dataset.target);
        this.init_editor(this.el).root.innerHTML = tartget_input.value;
    },
};

// Hooks.ScrollPagination = {
//   mounted() {
//     // 獲取DOM元素
//     const container = this.el;
//     const itemList = container.querySelector(".item-list");
//     const prevBtn = container.querySelector(".prev");
//     const nextBtn = container.querySelector(".next");

//     // 計算尺寸和頁數
//     let containerWidth = container.offsetWidth;
//     let totalWidth = itemList.scrollWidth;
//     let total_page = Math.ceil(totalWidth / containerWidth);
//     let current_page = 1;
//     let isAnimating = false;

//     // 更新按鈕顯示狀態
//     const updateButtons = () => {
//       nextBtn.style.visibility = current_page < total_page ? "visible" : "hidden";
//       prevBtn.style.visibility = current_page > 1 ? "visible" : "hidden";
//     };

//     // 計算下一頁的偏移量
//     const calculateNextOffset = (currentPage, containerWidth, totalPages, totalWidth) => {
//       let offset = currentPage * containerWidth;

//       // 最後一頁可能不需要完整滾動
//       if (currentPage + 1 === totalPages) {
//         offset -= (containerWidth - totalWidth % containerWidth);
//       }

//       return -offset;
//     };

//     // 計算上一頁的偏移量
//     const calculatePrevOffset = (currentPage, containerWidth) => {
//       return -(currentPage - 2) * containerWidth;
//     };

//     // 滾動到指定位置，帶動畫效果
//     const scrollWithAnimation = (targetOffset) => {
//       if (isAnimating) return;
//       isAnimating = true;

//       const startOffset = parseInt(getComputedStyle(itemList).transform.split(',')[4]) || 0;
//       const distance = targetOffset - startOffset;
//       const duration = 500; // 動畫持續時間（毫秒）
//       const startTime = performance.now();

//       // 動畫函數
//       const animate = (currentTime) => {
//         const elapsedTime = currentTime - startTime;
//         const progress = Math.min(elapsedTime / duration, 1);

//         // 使用緩動函數使動畫更自然
//         const easeOutCubic = 1 - Math.pow(1 - progress, 3);
//         const currentOffset = startOffset + distance * easeOutCubic;

//         itemList.style.transform = `translateX(${currentOffset}px)`;

//         if (progress < 1) {
//           requestAnimationFrame(animate);
//         } else {
//           isAnimating = false;
//         }
//       };

//       requestAnimationFrame(animate);
//     };

//     // 處理滾動
//     const scrollItems = (direction) => {
//       let targetOffset;

//       if (direction === "next" && current_page < total_page) {
//         targetOffset = calculateNextOffset(current_page, containerWidth, total_page, totalWidth);
//         current_page += 1;
//       } else if (direction === "prev" && current_page > 1) {
//         targetOffset = calculatePrevOffset(current_page, containerWidth);
//         current_page -= 1;
//       } else {
//         return; // 無效的滾動方向或已到達邊界
//       }

//       scrollWithAnimation(targetOffset);
//       updateButtons();
//     };

//     // 監聽按鈕點擊事件
//     prevBtn.addEventListener("click", (e) => {
//       e.preventDefault();
//       scrollItems("prev");
//     });

//     nextBtn.addEventListener("click", (e) => {
//       e.preventDefault();
//       scrollItems("next");
//     });

//     // 處理窗口大小變化
//     const handleResize = () => {
//       // 重新計算尺寸
//       containerWidth = container.offsetWidth;
//       totalWidth = itemList.scrollWidth;
//       total_page = Math.ceil(totalWidth / containerWidth);

//       // 確保當前頁不超過總頁數
//       current_page = Math.min(current_page, total_page);

//       // 重新定位到當前頁
//       const offset = calculatePrevOffset(current_page + 1, containerWidth);
//       itemList.style.transform = `translateX(${offset}px)`;

//       updateButtons();
//     };

//     window.addEventListener("resize", handleResize);
//     this.handleResize = handleResize; // 保存引用以便在destroyed中移除

//     // 初始化：檢查是否有活動項目需要滾動到視圖中
//     const btnNavActive = itemList.querySelector('.btn-nav-active');
//     if (btnNavActive) {
//       const itemListRect = itemList.getBoundingClientRect();
//       const btnNavActiveRect = btnNavActive.getBoundingClientRect();
//       const distance = btnNavActiveRect.right - itemListRect.left;
//       const translate = Math.ceil(distance / containerWidth);

//       if (translate > 1) {
//         const offset = calculateNextOffset(translate - 1, containerWidth, total_page, totalWidth);
//         itemList.style.transform = `translateX(${offset}px)`;
//         current_page = translate;
//       }
//     }

//     // 初始化按鈕狀態
//     updateButtons();
//   },

//   updated() {
//     // 如果內容更新，重新計算並調整
//     if (this.handleResize) {
//       this.handleResize();
//     }
//   },

//   destroyed() {
//     // 清理事件監聽器
//     if (this.handleResize) {
//       window.removeEventListener("resize", this.handleResize);
//     }
//   }
// };

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

        // 觸控相關變數
        let touchStartX = 0;
        let touchEndX = 0;
        let currentTranslateX = 0;
        let initialTranslateX = 0;
        let isTouching = false;

        // 更新按鈕顯示狀態
        const updateButtons = () => {
            nextBtn.style.visibility =
                current_page < total_page ? "visible" : "hidden";
            prevBtn.style.visibility = current_page > 1 ? "visible" : "hidden";
        };

        // 計算下一頁的偏移量
        const calculateNextOffset = (
            currentPage,
            containerWidth,
            totalPages,
            totalWidth,
        ) => {
            let offset = currentPage * containerWidth;

            // 最後一頁可能不需要完整滾動
            if (currentPage + 1 === totalPages) {
                offset -= containerWidth - (totalWidth % containerWidth);
            }

            return -offset;
        };

        // 計算上一頁的偏移量
        const calculatePrevOffset = (currentPage, containerWidth) => {
            return -(currentPage - 2) * containerWidth;
        };

        // 獲取當前的transform偏移量
        const getCurrentTranslateX = () => {
            const transform = getComputedStyle(itemList).transform;
            if (transform === "none") return 0;
            return parseInt(transform.split(",")[4]) || 0;
        };

        // 滾動到指定位置，帶動畫效果
        const scrollWithAnimation = (targetOffset) => {
            if (isAnimating) return;
            isAnimating = true;

            const startOffset = getCurrentTranslateX();
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
                targetOffset = calculateNextOffset(
                    current_page,
                    containerWidth,
                    total_page,
                    totalWidth,
                );
                current_page += 1;
            } else if (direction === "prev" && current_page > 1) {
                targetOffset = calculatePrevOffset(
                    current_page,
                    containerWidth,
                );
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

        // 處理觸控開始事件
        const handleTouchStart = (e) => {
            if (isAnimating) return;

            touchStartX = e.touches[0].clientX;
            initialTranslateX = getCurrentTranslateX();
            currentTranslateX = initialTranslateX;
            isTouching = true;
        };

        // 處理觸控移動事件
        const handleTouchMove = (e) => {
            if (!isTouching || isAnimating) return;

            const currentX = e.touches[0].clientX;
            const diffX = currentX - touchStartX;

            // 計算最大可移動範圍
            const maxRight = 0;
            const maxLeft = -totalWidth + containerWidth;

            // 計算新的偏移量（增加阻尼效果，超出範圍時移動變慢）
            let newTranslateX = initialTranslateX + diffX;

            if (newTranslateX > maxRight) {
                // 向右超出範圍
                newTranslateX = maxRight + (newTranslateX - maxRight) * 0.2;
            } else if (newTranslateX < maxLeft) {
                // 向左超出範圍
                newTranslateX = maxLeft + (newTranslateX - maxLeft) * 0.2;
            }

            currentTranslateX = newTranslateX;
            itemList.style.transform = `translateX(${newTranslateX}px)`;

            // 防止頁面滾動
            e.preventDefault();
        };

        // 處理觸控結束事件
        const handleTouchEnd = (e) => {
            if (!isTouching) return;
            isTouching = false;

            touchEndX = e.changedTouches[0].clientX;
            const diffX = touchEndX - touchStartX;
            const swipeThreshold = containerWidth * 0.2; // 20% 的容器寬度

            if (Math.abs(diffX) > swipeThreshold) {
                // 有效的滑動手勢
                if (diffX > 0 && current_page > 1) {
                    // 向右滑動 -> 上一頁
                    scrollItems("prev");
                } else if (diffX < 0 && current_page < total_page) {
                    // 向左滑動 -> 下一頁
                    scrollItems("next");
                } else {
                    // 滑動方向有效，但已到達邊界，回到原位置
                    scrollWithAnimation(initialTranslateX);
                }
            } else {
                // 滑動幅度不夠，回到原位置
                scrollWithAnimation(initialTranslateX);
            }
        };

        // 處理觸控取消事件
        const handleTouchCancel = () => {
            if (isTouching) {
                isTouching = false;
                // 回到原位置
                scrollWithAnimation(initialTranslateX);
            }
        };

        // 處理窗口大小變化
        const handleResize = () => {
            // 重新計算尺寸
            containerWidth = container.offsetWidth;
            totalWidth = itemList.scrollWidth;
            total_page = Math.ceil(totalWidth / containerWidth);

            // 確保當前頁不超過總頁數
            current_page = Math.min(current_page, total_page);

            // 重新定位到當前頁
            const offset = calculatePrevOffset(
                current_page + 1,
                containerWidth,
            );
            itemList.style.transform = `translateX(${offset}px)`;

            updateButtons();
        };

        // 註冊觸控事件
        itemList.addEventListener("touchstart", handleTouchStart, {
            passive: false,
        });
        itemList.addEventListener("touchmove", handleTouchMove, {
            passive: false,
        });
        itemList.addEventListener("touchend", handleTouchEnd);
        itemList.addEventListener("touchcancel", handleTouchCancel);

        window.addEventListener("resize", handleResize);

        // 保存事件處理函數引用以便在destroyed中移除
        this.eventHandlers = {
            handleResize,
            handleTouchStart,
            handleTouchMove,
            handleTouchEnd,
            handleTouchCancel,
        };

        // 初始化：檢查是否有活動項目需要滾動到視圖中
        const btnNavActive = itemList.querySelector(".btn-nav-active");
        if (btnNavActive) {
            const itemListRect = itemList.getBoundingClientRect();
            const btnNavActiveRect = btnNavActive.getBoundingClientRect();
            const distance = btnNavActiveRect.right - itemListRect.left;
            const translate = Math.ceil(distance / containerWidth);

            if (translate > 1) {
                const offset = calculateNextOffset(
                    translate - 1,
                    containerWidth,
                    total_page,
                    totalWidth,
                );
                itemList.style.transform = `translateX(${offset}px)`;
                current_page = translate;
            }
        }

        // 初始化按鈕狀態
        updateButtons();
    },

    updated() {
        // 如果內容更新，重新計算並調整
        if (this.eventHandlers && this.eventHandlers.handleResize) {
            this.eventHandlers.handleResize();
        }
    },

    destroyed() {
        // 清理事件監聽器
        if (this.eventHandlers) {
            window.removeEventListener(
                "resize",
                this.eventHandlers.handleResize,
            );

            const itemList = this.el.querySelector(".item-list");
            if (itemList) {
                itemList.removeEventListener(
                    "touchstart",
                    this.eventHandlers.handleTouchStart,
                );
                itemList.removeEventListener(
                    "touchmove",
                    this.eventHandlers.handleTouchMove,
                );
                itemList.removeEventListener(
                    "touchend",
                    this.eventHandlers.handleTouchEnd,
                );
                itemList.removeEventListener(
                    "touchcancel",
                    this.eventHandlers.handleTouchCancel,
                );
            }
        }
    },
};

Hooks.Splide = {
    mounted() {
        const splide = new Splide(this.el).mount();
    },
    updated() {
        const splide = new Splide(this.el).mount();
    },
};

Hooks.ShareHook = {
    mounted() {
        this.url = encodeURIComponent(
            document.querySelector("meta[name='twitter:url']")?.content ||
                document.querySelector("meta[property='og:url']")?.content ||
                window.location.href,
        );
        this.title = encodeURIComponent(
            document.querySelector("meta[name='twitter:title']")?.content ||
                document.querySelector("meta[property='og:title']")?.content ||
                document.title,
        );
        this.description = encodeURIComponent(
            document.querySelector("meta[name='twitter:description']")
                ?.content ||
                document.querySelector("meta[property='og:description']")
                    ?.content ||
                "",
        );
        this.image = encodeURIComponent(
            document.querySelector("meta[name='twitter:image']")?.content ||
                document.querySelector("meta[property='og:image']")?.content ||
                "",
        );

        this.shareLinks = {
            facebook: `https://www.facebook.com/sharer/sharer.php?u=${this.url}`,
            twitter: `https://twitter.com/intent/tweet?url=${this.url}&text=${this.title}`,
            linkedin: `https://www.linkedin.com/shareArticle?mini=true&url=${this.url}&title=${this.title}&summary=${this.description}`,
        };

        let platform = this.el.dataset.share;

        if (platform) {
            this.el.addEventListener("click", (event) => {
                if (this.shareLinks[platform]) {
                    window.open(
                        this.shareLinks[platform],
                        "_blank",
                        "width=600,height=400,scrollbars=yes,resizable=yes",
                    );
                }
            });
        }
    },
};

export default Hooks;
