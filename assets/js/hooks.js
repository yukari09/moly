import EditorJS from '@editorjs/editorjs'
import Header from "@editorjs/header"
import LazyLoad from "vanilla-lazyload"
import flatpickr from "flatpickr"
import { DateTime } from "luxon"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let Hooks = {}


Hooks.Editor = {
  mounted() {
    const editor = new EditorJS({
      /**
       * Id of Element that should contain the Editor
       */
      holder : this.el,
      placeholder: this.el.dataset.placeholder,
      /**
       * Available Tools list.
       * Pass Tool's class or Settings object for each Tool you want to use
       */
      tools: {
        header: {
          class: Header,
          inlineToolbar : true
        },
        // ...
      },
    
      /**
       * Previously saved data that should be rendered
       */
      data: {}
    });
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
        const targetElement = document.querySelector(this.el.dataset.utcTarget)
        if (targetElement) {
          const utcDateTime = DateTime.fromISO(this.el.value, { zone: "utc" })
          const localDateTime = utcDateTime.setZone(DateTime.local().zoneName).toLocaleString(DateTime.DATETIME_MED) 
          targetElement.textContent = localDateTime
        }
      }    
    });
  }
}

Hooks.LocalizeDateTime = {
  mounted() {
    this.localizeText();
  },
  localizeText() {
    const utcText = this.el.innerText
    if (utcText) {
      const utcDateTime = DateTime.fromISO(utcText, { zone: "utc" });
      const localDateTime = utcDateTime.setZone(DateTime.local().zoneName).toLocaleString(DateTime.DATETIME_MED);
      this.el.innerText = localDateTime;
    }
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

export default Hooks
