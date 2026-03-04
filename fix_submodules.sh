#!/bin/bash
set -e  # 遇到错误立即停止

echo "1. 备份项目..."
cp -r /mnt/TWET-20250901A/ymm /tmp/ymm_backup
echo "备份完成"

echo "2. 删除嵌套 .git 目录..."
find . -mindepth 2 -name ".git" -exec rm -rf {} + 2>/dev/null
echo "完成"

echo "3. 删除嵌套 .gitmodules 文件..."
find . -mindepth 2 -name ".gitmodules" -exec rm -f {} + 2>/dev/null
echo "完成"

echo "4. 清理 submodule 注册信息..."
rm -rf .git/modules
rm -f .gitmodules
echo "完成"

echo "5. 重新添加所有文件..."
git add .
git commit -m "convert all submodules to regular directories"
echo "完成"

echo "6. 推送到远程..."
git push origin main
echo "全部完成！"