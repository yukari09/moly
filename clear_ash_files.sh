#!/bin/bash

# 设置路径
resource_snapshots_dir="_build/dev/lib/monorepo/priv/resource_snapshots"
migrations_dir="_build/dev/lib/monorepo/priv/repo/migrations"

# 删除 resource_snapshots 目录
if [ -d "$resource_snapshots_dir" ]; then
  echo "删除目录：$resource_snapshots_dir"
  rm -rf "$resource_snapshots_dir"
else
  echo "目录 $resource_snapshots_dir 不存在"
fi

# 删除匹配的 .exs 文件
migrations_files=$(find "$migrations_dir" -type f -name '20*.exs')

if [ -n "$migrations_files" ]; then
  echo "删除以下文件："
  echo "$migrations_files"
  rm -f $migrations_files
else
  echo "没有找到匹配的文件：$migrations_dir/20*.exs"
fi

echo "脚本执行完毕。"