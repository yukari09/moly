import {Resize, TagsTagify} from "./hooks/post.js"

// let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")


let Hooks = {}

Hooks.Resize = Resize
Hooks.TagsTagify = TagsTagify


// Hooks.ScrollPagination = {
//     mounted() {
//         const container = this.el;
//         const itemList = container.querySelector(".item-list");  
//         const prevBtn = container.querySelector(".prev");  
//         const nextBtn = container.querySelector(".next"); 

//         const containerWidth = container.offsetWidth;  
//         const totalWidth = itemList.scrollWidth;  

//         const total_page = Math.ceil(totalWidth/containerWidth);

//         let current_page = 1;


//         const updateButtons = () => {

//             nextBtn.style.visibility = current_page < total_page ? "visible" : "hidden";
//             prevBtn.style.visibility = current_page > 1 ? "visible" : "hidden";

//         };

//         const next_page = (cp, cw, tp, tw) => {
//             let currentOffset = (cp) * cw
//             if(cp + 1 === tp){
//                 currentOffset -= (cw - tw%cw)
//             }
//             currentOffset = -currentOffset
//             return currentOffset
//         }

//         const prev_page = (cp, cw) => {
//             let currentOffset = (cp - 2) * cw
//             currentOffset = - currentOffset
//             return currentOffset
//         }

//         const scrollItems = (direction) => {
//             if (direction === "next") {                
//                 currentOffset = next_page(current_page, containerWidth, total_page, totalWidth)
//                 current_page += 1
//             } else if (direction === "prev") {
//                 currentOffset = prev_page(current_page, containerWidth)
//                 current_page -= 1
//             }

//             itemList.style.transform = `translateX(${currentOffset}px)`;
//             updateButtons();  
//         };


//         prevBtn.addEventListener("click", (e) => {
//             e.preventDefault();
//             if(current_page > 1){
//                 scrollItems("prev");
//             }
//         });

//         nextBtn.addEventListener("click", (e) => {
//             e.preventDefault();
//             if(current_page < total_page){
//                 scrollItems("next");
//             }
//         });

//         const btnNavActive = itemList.querySelector('.btn-nav-active');

//         if (btnNavActive) {
//             const itemListRect = itemList.getBoundingClientRect();
//             const btnNavActiveRect = btnNavActive.getBoundingClientRect();
//             const distance = btnNavActiveRect.right - itemListRect.left;

//             const translate = Math.ceil(distance/containerWidth);

//             if(translate > 1){
//                 let currentOffset = next_page(translate - 1, containerWidth, total_page, totalWidth)
//                 itemList.style.transform = `translateX(${currentOffset}px)`;
//                 current_page = translate;
//             }

//         }
//         updateButtons();
//     }
// }

export default Hooks
