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
import LazyLoad from "vanilla-lazyload";

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

Hooks.CfTurnstile = {
    renderTurnstile(el) {
        const callback = el.dataset.callback;

        turnstile.render(el, {
            sitekey: el.dataset.sitekey,
            callback: (token) => {
                if (callback) {
                    window.dispatchEvent(
                        new CustomEvent(callback, { detail: { token, el } }),
                    );
                }
            },
        });
    },

    load_script(el) {
        const existingScript = document.querySelector(
            "script[src*='turnstile']",
        );
        if (typeof turnstile !== "undefined") {
            this.renderTurnstile(el);
            return;
        }

        if (existingScript) {
            const interval = setInterval(() => {
                if (typeof turnstile !== "undefined") {
                    clearInterval(interval);
                    this.renderTurnstile(el);
                }
            }, 100);
            return;
        }

        const src =
            "https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onloadTurnstileCallback";
        const script = document.createElement("script");
        script.src = src;
        script.async = true;
        document.head.appendChild(script);

        window.onloadTurnstileCallback = () => {
            this.renderTurnstile(el);
        };
    },

    mounted() {
        this.load_script(this.el);
    },

    updated() {
        this.load_script(this.el);
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

        // Share links for various platforms
        this.shareLinks = {
            facebook: `https://www.facebook.com/sharer/sharer.php?u=${this.url}`,
            twitter: `https://twitter.com/intent/tweet?url=${this.url}&text=${this.title}`,
            reddit: `https://www.reddit.com/submit?url=${this.url}&title=${this.title}`, // Changed to Reddit
            threads: `https://www.threads.net/share?url=${this.url}&text=${this.title}`, // Threads share link
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

Hooks.lazyLoadImage = {
    mounted() {
        this.lazyLoadInstance = new LazyLoad(this.el);
    },
    updated() {
        this.lazyLoadInstance.update();
    },
    destroyed() {
        this.lazyLoadInstance = null;
    },
};

export default Hooks;
