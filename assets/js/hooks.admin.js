import {
    SetFeatureImage,
    PostDatetimePicker,
    InputValueUpdater,
    TagsTagify,
    Editor,
    FormChangeListener,
    Resize,
    SelectAll
} from "./hooks/post.js";

import AceEditor from "./hooks/ace.js" ;

let Hooks = {};

Hooks.SetFeatureImage = SetFeatureImage;
Hooks.PostDatetimePicker = PostDatetimePicker;
Hooks.InputValueUpdater = InputValueUpdater;
Hooks.TagsTagify = TagsTagify;
Hooks.Editor = Editor;
Hooks.FormChangeListener = FormChangeListener;
Hooks.Resize = Resize;
Hooks.SelectAll = SelectAll;
Hooks.AceEditor = AceEditor;
 

export default Hooks;