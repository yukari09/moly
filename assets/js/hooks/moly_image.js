import { IconAddBorder, IconStretch, IconAddBackground, IconPicture, IconText } from '@codexteam/icons';


class MolyImage {
  constructor({ data, api, config }) {
    this.data = data;
    this.api = api;
    this.config = config;
    this.wrapper = undefined;
  }

  static get toolbox() {
    return {
      title: 'Meida',
      icon: IconPicture
    };
  }

  render() {
    // this.config.modal
    console.log(this.config.modal)
    const el = window.document.querySelector(this.config.modal);
    liveSocket.execJS(el, el.getAttribute("data-show-modal"))
    this.wrapper = document.createElement('div');
    return this.wrapper;
  }

  save(blockContent) {
    return {
      text: "t"
    };
  }
}
// class MolyImage {
//   constructor({ data }) {
//     this.data = data;
//     this.wrapper = undefined;
//   }

//   static get toolbox() {
//     return {
//       title: 'Meida',
//       icon: IconPicture
//     };
//   }

//   render() {
//     this.wrapper = document.createElement('div');
//     const input = document.createElement('img');
//     input.placeholder = 'Enter text here...';
//     if (this.data && this.data.text) {
//       input.value = this.data.text;
//     }
//     this.wrapper.appendChild(input);
//     return this.wrapper;
//   }

//   save(blockContent) {
//     return {
//       text: blockContent.querySelector('input').value
//     };
//   }

//   // Optional: Add a validation for empty input
//   validate(savedData) {
//     if (!savedData.text || savedData.text.trim() === '') {
//       return false;
//     }
//     return true;
//   }
// }

export default MolyImage;