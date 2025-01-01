// import * as UpChunk from "@mux/upchunk"

let Uploaders = {}

Uploaders.S3 = function (entries, onViewError) {
  entries.forEach(entry => {
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort())
    xhr.onload = () => xhr.status === 200 ? entry.progress(100) : entry.error()
    xhr.onerror = () => entry.error()
  
    xhr.upload.addEventListener("progress", (event) => {
      if(event.lengthComputable){
        let percent = Math.round((event.loaded / event.total) * 100)
        if(percent < 100){ entry.progress(percent) }
      }
    })
  
    let url = entry.meta.url
    xhr.open("PUT", url, true)
    xhr.send(entry.file)
  })
}

// Uploaders.UpChunk = function(entries, onViewError){
//     entries.forEach(entry => {
//       // create the upload session with UpChunk
//       let { file, meta: { entrypoint } } = entry
//       let upload = UpChunk.createUpload({ endpoint: entrypoint, file })
  
//       // stop uploading in the event of a view error
//       onViewError(() => upload.pause())
  
//       // upload error triggers LiveView error
//       upload.on("error", (e) => entry.error(e.detail.message))
  
//       // notify progress events to LiveView
//       upload.on("progress", (e) => {
//         if(e.detail < 100){ entry.progress(e.detail) }
//       })
  
//       // success completes the UploadEntry
//       upload.on("success", () => entry.progress(100))
//     })
//   }

export default Uploaders;