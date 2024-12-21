import EasyMDE from "easymde"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}

Hooks.Editor = {
    // uploadImage(editor) {
    //   var input = document.createElement('input');
    //   input.type = 'file';
    //   input.accept = 'image/*';
    //   input.onchange = function() {
    //     var file = input.files[0];
    //     if (file) {
    //       var formData = new FormData();
    //       formData.append('file', file);
    //       formData.append('_csrf_token', csrfToken)
    //       fetch('/upload-image', {
    //         method: 'POST',
    //         body: formData
    //       }).then(response => response.json()).then(data => {
    //         if (data.url) {
    //           var cm = editor.codemirror;
    //           var output = `![alt text](${data.url})`;
    //           cm.replaceSelection(output);
    //         }
    //       }).catch(error => {
    //         console.error('Error uploading image:', error);
    //       });
    //     }
    //   };
    //   input.click();
    // },
    // imageUploadFunction(file, onSuccess, onError) {
    //   let formData = new FormData();
    //   formData.append('file', file);
    //   formData.append('_csrf_token', csrfToken); // 添加 CSRF 令牌
    //   fetch('/upload-image', {
    //     method: 'POST',
    //     body: formData
    //   }).then(response => response.json()).then(data => {
    //     if (data.url) {
    //       onSuccess(data.url);
    //     } else {
    //       onError('Upload failed');
    //     }
    //   }).catch(() => {
    //     onError('Upload failed');
    //   });
    // },
    mounted() {
      _thisUniqueId = this.el.getAttribute("id")
    //   _uploadimage = this.uploadImage
    //   _imageUploadFunction = this.imageUploadFunction
      _targeElId = `#${this.el.dataset.target}`
      const easyMDE = new EasyMDE({
        element: this.el,
        maxHeight: "480px",
        // autosave: {
        //     enabled: true,
        //     uniqueId: _thisUniqueId,
        //     delay: 1000,
        //     submit_delay: 5000,
        //     timeFormat: {
        //         locale: 'en-US',
        //         format: {
        //             year: 'numeric',
        //             month: 'long',
        //             day: '2-digit',
        //             hour: '2-digit',
        //             minute: '2-digit',
        //         },
        //     },
        //     text: "Autosaved: "
        // },            
        toolbar: [
            "bold", "italic", "heading", "|", "quote", "unordered-list", "ordered-list", "|", "link", "image", "|", "preview", "side-by-side", "fullscreen", "|"
            // {
            //     name: "upload-image",
            //     action: function customFunction(editor) {
            //         _uploadimage(editor);
            //     },
            //     className: "fa fa-upload",
            //     title: "Upload Image",
            // }
        ]
      })
      easyMDE.codemirror.on("change", function() {
        document.querySelector(_targeElId).value = easyMDE.value()
      })
    //   easyMDE.codemirror.on('drop', function(editor, event) {
    //     event.stopPropagation();
    //     event.preventDefault();
    //     const files = event.dataTransfer.files;
    //     if (files.length > 0) {
    //       for (let i = 0; i < files.length; i++) {
    //         const file = files[i];
    //         if (file.type.startsWith('image/')) {
    //           _imageUploadFunction(file, function(url) {
    //             const cm = editor.getDoc();
    //             const pos = cm.getCursor();
    //             cm.replaceRange(`![image](${url})\n`, pos);
    //           }, function(error) {
    //             console.error(error);
    //           });
    //         }
    //       }
    //     }
    //   })
    }
  }

export default Hooks