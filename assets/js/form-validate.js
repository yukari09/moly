// js/form-validate.js

// 輔助函數
const getTrimmedString = (value) => {
  return value !== null && value !== undefined ? value.toString().trim() : "";
};

const isValidNumber = (value) => {
  return !isNaN(parseFloat(value)) && isFinite(value);
};

const isValidEmail = (value) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(value);
};

const isValidURL = (value) => {
  try {
    new URL(value);
    return true;
  } catch {
    return false;
  }
};

const isValidDate = (value) => {
  const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
  return dateRegex.test(value) && !isNaN(new Date(value).getTime());
};

export const countWords = (text) => {
  /**
   * 計算文本中不同語言的字數，支持多語言混合。
   *
   * @param {string} text - 輸入的文本。
   * @returns {number} 各類字符的總字數（不包括符號和其他非語言字符）。
   */
  // 定義正則表達式匹配不同類型的字符
  const patterns = {
    chinese: /[\u4e00-\u9fff]/g, // 中文字符
    japanese: /[\u3040-\u30ff\u31f0-\u31ff\uff66-\uff9f]/g, // 日文假名
    korean: /[\uac00-\ud7af\u1100-\u11ff\u3130-\u318f]/g, // 韓文字母
    english: /\b[a-zA-Z]+\b/g, // 英文字母（單詞）
    russian: /\b[\u0400-\u04FF]+\b/g, // 俄文字母（單詞）
    digits: /\b[0-9]+\b/g // 數字（整體匹配）
  };

  // 初始化統計結果
  const counts = Object.fromEntries(Object.keys(patterns).map(key => [key, 0]));

  // 計算每一類字符的數量
  for (const [key, pattern] of Object.entries(patterns)) {
    const matches = text.match(pattern);
    if (matches) {
      counts[key] = matches.length; // 確保所有類型按匹配次數計算
    }
  }

  // 計算總字數（不包括符號和其他非語言字符）
  const totalWords = Object.values(counts).reduce((sum, count) => sum + count, 0);
  return totalWords;
};

// 主驗證器
export const Validators = {
  required: (value, msg = "This field is required.") => {
    return getTrimmedString(value) !== "" ? true : msg;
  },
  length: (value, min, max, msg) => {
    const totalWords = countWords(value);
    return totalWords >= min && totalWords <= max ? true : msg || `The length must be between ${min} and ${max} words.`;
  },
  range: (value, min, max, msg) => {
    const num = parseFloat(value);
    return !isNaN(num) && num >= min && num <= max ? true : msg || `The value must be between ${min} and ${max}.`;
  },
  isNumber: (value, msg = "This field must be a valid number.") => {
    return isValidNumber(value) ? true : msg;
  },
  isEmail: (value, msg = "This field must be a valid email address.") => {
    return isValidEmail(value) ? true : msg;
  },
  isURL: (value, msg = "This field must be a valid URL.") => {
    return isValidURL(value) ? true : msg;
  },
  matches: (value, regex, msg = "The value does not match the required format.") => {
    return regex.test(value) ? true : msg;
  },
  isDate: (value, msg = "This field must be a valid date (YYYY-MM-DD).") => {
    return isValidDate(value) ? true : msg;
  },
  isBoolean: (value, msg = "This field must be true or false.") => {
    return typeof value === "boolean" ? true : msg;
  },
  isInteger: (value, msg = "This field must be an integer.") => {
    return Number.isInteger(Number(value)) ? true : msg;
  },
  isUpperCase: (value, msg = "This field must be in uppercase.") => {
    return getTrimmedString(value) === value.toUpperCase() ? true : msg;
  },
  isLowerCase: (value, msg = "This field must be in lowercase.") => {
    return getTrimmedString(value) === value.toLowerCase() ? true : msg;
  },
  inList: (value, list, msg = "This field must be one of the allowed values.") => {
    return list.includes(value) ? true : msg;
  },
  isPhoneNumber: (value, msg = "This field must be a valid phone number.") => {
    const phoneRegex = /^\+?[1-9]\d{1,14}$/; // E.164 標準
    return phoneRegex.test(value) ? true : msg;
  },
  isJSON: (value, msg = "This field must be a valid JSON string.") => {
    try {
      JSON.parse(value);
      return true;
    } catch {
      return msg;
    }
  }
};
