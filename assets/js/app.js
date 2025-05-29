import Alpine from 'alpinejs'
window.Alpine = Alpine
window.csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
Alpine.start()