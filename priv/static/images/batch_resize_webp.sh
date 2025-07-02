#!/bin/bash

# --- 配置參數 ---
# 設定目標寬度。0 表示自動調整高度以保持長寬比。
# 這裡固定為你的需求：寬度 150px，高度自動
TARGET_WIDTH=150
TARGET_HEIGHT=0

# 輸出目錄的名稱。所有處理後的 WebP 圖片將會存放在這裡。
OUTPUT_DIR="resized_webp_output"

# 輸出文件名的後綴 (例如：-w150)
OUTPUT_SUFFIX="-w${TARGET_WIDTH}" # 自動生成為 -w150

# --- 結束配置 ---

# 檢查 cwebp 工具是否存在
if ! command -v cwebp &> /dev/null
then
    echo "錯誤: cwebp 命令未找到。請確保已安裝 libwebp 工具包並將其添加到 PATH 中。"
    echo "您可以從 https://developers.google.com/speed/webp/download 下載。"
    exit 1
fi

# 創建輸出目錄 (如果不存在)
mkdir -p "$OUTPUT_DIR"

echo "--- WebP 批量縮放工具 ---"
echo "處理目錄: $(pwd)"
echo "輸出目錄: $(pwd)/$OUTPUT_DIR"
echo "目標尺寸: 寬度 ${TARGET_WIDTH}px (高度自動按比例)"
echo "輸出文件後綴: ${OUTPUT_SUFFIX}.webp"
echo "----------------------"

# 查找當前目錄下所有的 .webp 文件
find . -maxdepth 1 -name "*.webp" -print0 | while IFS= read -r -d $'\0' input_file; do
    # 獲取不帶路徑的文件名
    filename=$(basename -- "$input_file")

    # 跳過已經帶有指定後綴的文件，避免重複處理
    if [[ "$filename" == *"${OUTPUT_SUFFIX}.webp" ]]; then
        echo "跳過已處理文件: $filename"
        continue
    fi

    # 獲取不帶擴展名的檔案名稱
    filename_no_ext="${filename%.webp}"

    # 定義輸出檔案的路徑和名稱
    # 範例: bear-6e0b3c908c00af26d5bbb2054ddc6f9d-w150.webp
    output_file="$OUTPUT_DIR/${filename_no_ext}${OUTPUT_SUFFIX}.webp"

    echo "正在處理：$filename -> $output_file"

    # 執行 cwebp 命令進行縮放和轉換
    # 注意: 對於 webp 到 webp 的轉換，cwebp 默認會嘗試無損壓縮，
    # 或者保留原始 webp 的壓縮類型 (如果有)。
    # 如果你明確需要無損，可以加上 -lossless 參數。
    cwebp "$input_file" -resize "$TARGET_WIDTH" "$TARGET_HEIGHT" -o "$output_file"

    # 檢查 cwebp 命令是否成功執行
    if [ $? -eq 0 ]; then
        echo "  ✓ 成功轉換：$output_file"
    else
        echo "  ✗ 錯誤: 轉換 $filename 失敗！"
    fi
done

echo "--- 批量處理完成！ ---"
echo "所有縮放後的 WebP 圖片位於: $(pwd)/$OUTPUT_DIR"