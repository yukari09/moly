// import Quill, { Delta } from "quill";

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {};

Hooks.DescriptionEditor = {
    init_editor(el) {
        return new Promise((resolve) => {
            const initQuillEditor = () => {
                const config = JSON.parse(el.dataset.config);
                const tartget_input = document.querySelector(el.dataset.target);
                const Delta = Quill.import('delta');
                
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
                quillInstance.on("text-change", function() {
                    let editorContent = quillInstance.root.innerHTML;
                    tartget_input.value = editorContent;
                    let event = new Event("input", {
                        bubbles: true,
                        cancelable: true,
                    });
                    tartget_input.dispatchEvent(event);
                });
                resolve(quillInstance);
            };

            if (typeof Quill === "undefined") {
                const libs = [
                    {
                        type: "js",
                        url: "https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.js",
                        id: "quill-js"
                    },
                    {
                        type: "css", 
                        url: "https://cdn.jsdelivr.net/npm/quill@2.0.3/dist/quill.snow.css",
                        id: "quill-css"
                    }
                ];
                
                const jsLib = libs.find(lib => lib.type === "js");
                const script = document.createElement("script");
                script.src = jsLib.url;
                script.id = jsLib.id;
                script.onload = initQuillEditor;
                
                libs.forEach(lib => {
                    if (lib.type === "css") {
                        const link = document.createElement("link");
                        link.href = lib.url;
                        link.id = lib.id;
                        link.rel = "stylesheet";
                        document.head.appendChild(link);
                    }
                });
                
                document.head.appendChild(script);
            } else {
                initQuillEditor();
            }
        });
    },
    mounted() {
        this.init_editor(this.el);
    },
    updated() {
        const tartget_input = document.querySelector(this.el.dataset.target);
        this.init_editor(this.el).root.innerHTML = tartget_input.value;
    },
};

// Hook to dynamically load CSS/JS libraries
// Usage: Add data-lib attribute with JSON config to an element
// Example: data-libs=[{ "type": "css", "url": "https://example.com/style.css", "id": "example-css" }]
Hooks.DynamicLoadLibraries = {
    loadLibrary(libData) {
        try {
            // Handle CSS files
            if (libData.type === "css") {
                // Check if CSS is already loaded
                const existingLink = document.getElementById(libData.id);
                if (!existingLink) {
                    // Create and append link element
                    const link = document.createElement("link");
                    link.href = libData.url;
                    link.id = libData.id;
                    link.rel = "stylesheet";
                    document.head.appendChild(link);
                }
            // Handle JavaScript files 
            } else if (libData.type === "js") {
                // Check if script is already loaded
                const existingScript = document.getElementById(libData.id);
                if (!existingScript) {
                    // Create and append script element
                    const script = document.createElement("script");
                    script.src = libData.url;
                    script.id = libData.id;
                    script.async = true; 
                    document.head.appendChild(script);
                }
            }
        } catch (error) {
            console.error("Error loading library:", error);
        }
    },
    loadLibraries(el) {
        const libDatas = JSON.parse(el.dataset.libs || "[]");
        // Check if libDatas is an array
        if (!libDatas || !Array.isArray(libDatas)) {
            console.error("Invalid libraries data:", libDatas);
            return;
        }
        libDatas.forEach((libData) => {
            // Check if libData is an object and has the required properties
            if (libData && typeof libData === "object" && libData.url) {
                // Check if the library is already loaded
                const existingLib = document.getElementById(libData.id);
                if (!existingLib) {
                    this.loadLibrary(libData);
                }
            } else {
                console.error("Invalid library data:", libData);
            }
        });
    },
    mounted() {
        this.loadLibraries(this.el);
    },
    updated() {
        this.loadLibraries(this.el);
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

export default Hooks;
