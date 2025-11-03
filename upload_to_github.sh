#!/bin/bash

# V2bX Socks5 版本上传到 GitHub 脚本
# 使用方法: bash upload_to_github.sh YOUR_GITHUB_USERNAME

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}错误: 缺少 GitHub 用户名参数${NC}"
    echo "使用方法: bash upload_to_github.sh YOUR_GITHUB_USERNAME"
    exit 1
fi

GITHUB_USERNAME="$1"
REPO_NAME="${2:-V2bX-socks5}"

echo -e "${GREEN}=== V2bX Socks5 上传到 GitHub ===${NC}"
echo "GitHub 用户名: $GITHUB_USERNAME"
echo "仓库名称: $REPO_NAME"
echo ""

# 步骤 1: 检查 Git 状态
echo -e "${YELLOW}[1/8] 检查 Git 状态...${NC}"
if [ ! -d ".git" ]; then
    echo -e "${RED}错误: 当前目录不是 Git 仓库${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Git 仓库检查通过${NC}"

# 步骤 2: 更新 .gitignore
echo -e "${YELLOW}[2/8] 更新 .gitignore...${NC}"
cat >> .gitignore <<EOF

# V2bX Socks5 编译产物
V2bX-linux-amd64
V2bX-socks5-linux-amd64.tar.gz
*.tar.gz
dist_socks/*.tar.gz
EOF
echo -e "${GREEN}✓ .gitignore 已更新${NC}"

# 步骤 3: 添加文件到 Git
echo -e "${YELLOW}[3/8] 添加文件到 Git...${NC}"
git add core/xray/socks.go
git add dist_socks/
git add .gitignore
git add DEPLOY_GUIDE.md
git add SOCKS5_README.md
git add api/panel/node.go api/panel/panel.go
git add core/sing/node.go
git add core/xray/inbound.go core/xray/user.go core/xray/xray.go
echo -e "${GREEN}✓ 文件已添加${NC}"

# 步骤 4: 提交到本地
echo -e "${YELLOW}[4/8] 提交到本地仓库...${NC}"
git commit -m "feat: 添加 Socks5 支持和一键安装功能

- 新增 Socks5 协议支持 (基于 Xray 核心)
- 添加 dist_socks 一键安装包和配置向导
- 支持 XBoard 面板对接
- 包含完整部署文档

新增文件:
- core/xray/socks.go - Socks5 协议实现
- dist_socks/ - 一键安装包
  - install_socks.sh - 安装脚本
  - initconfig.sh - 配置向导
  - config.json - 示例配置
- DEPLOY_GUIDE.md - 部署指南
- SOCKS5_README.md - Socks5 专用 README

修改文件:
- api/panel/node.go - 节点 API 对接
- core/sing/node.go - Sing-box 核心支持
- core/xray/*.go - Xray 核心增强
"
echo -e "${GREEN}✓ 已提交到本地${NC}"

# 步骤 5: 检查是否安装了 GitHub CLI
echo -e "${YELLOW}[5/8] 检查 GitHub CLI...${NC}"
if command -v gh &> /dev/null; then
    echo -e "${GREEN}✓ GitHub CLI 已安装${NC}"
    USE_GH_CLI=true
else
    echo -e "${YELLOW}⚠ GitHub CLI 未安装，将使用传统 Git 方式${NC}"
    echo "提示: 安装 GitHub CLI 可以自动创建仓库和 Release"
    echo "访问: https://cli.github.com/"
    USE_GH_CLI=false
fi

# 步骤 6: 创建远程仓库并推送
echo -e "${YELLOW}[6/8] 创建远程仓库并推送...${NC}"

if [ "$USE_GH_CLI" = true ]; then
    # 使用 GitHub CLI
    echo "正在创建 GitHub 仓库..."
    gh repo create "$REPO_NAME" --public --source=. --remote=origin --push || {
        echo -e "${YELLOW}⚠ 仓库可能已存在，尝试添加 remote...${NC}"
        git remote remove origin 2>/dev/null || true
        git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
        git push -u origin main
    }
    echo -e "${GREEN}✓ 已推送到 GitHub${NC}"
else
    # 传统 Git 方式
    echo -e "${YELLOW}请手动在 GitHub 创建仓库: $REPO_NAME${NC}"
    echo "1. 访问 https://github.com/new"
    echo "2. 仓库名称: $REPO_NAME"
    echo "3. 选择 Public"
    echo "4. 不要初始化 README"
    echo ""
    read -p "创建完成后按回车继续..."

    git remote remove origin 2>/dev/null || true
    git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    git branch -M main
    git push -u origin main
    echo -e "${GREEN}✓ 已推送到 GitHub${NC}"
fi

# 步骤 7: 创建 Release
echo -e "${YELLOW}[7/8] 创建 GitHub Release...${NC}"

if [ "$USE_GH_CLI" = true ]; then
    # 使用 GitHub CLI 创建 Release
    echo "正在创建 Release v1.0.0..."

    # 检查文件是否存在
    if [ ! -f "V2bX-socks5-linux-amd64.tar.gz" ]; then
        echo -e "${RED}错误: V2bX-socks5-linux-amd64.tar.gz 不存在${NC}"
        echo "请先编译或下载该文件"
        exit 1
    fi

    gh release create v1.0.0 \
        --title "V2bX Socks5 一键安装版 v1.0.0" \
        --notes "$(cat <<EOF
## V2bX Socks5 一键安装版

### 新增功能
- ✅ 支持 Socks5 协议（基于 Xray 核心）
- ✅ 一键安装脚本
- ✅ 配置向导支持
- ✅ 支持对接 XBoard 面板

### 支持的协议
- Shadowsocks
- Vless / Vmess
- Trojan
- Hysteria / Hysteria2
- Tuic
- **Socks5** ⭐

### 快速安装

\`\`\`bash
bash <(curl -fsSL https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/download/v1.0.0/install_socks.sh)
\`\`\`

### 系统要求
- CentOS 7+ / Ubuntu 16+ / Debian 8+
- 需要 root 权限
- V2board >= 1.7.0

### 使用文档
- [部署指南](https://github.com/$GITHUB_USERNAME/$REPO_NAME/blob/main/DEPLOY_GUIDE.md)
- [Socks5 专用文档](https://github.com/$GITHUB_USERNAME/$REPO_NAME/blob/main/SOCKS5_README.md)
EOF
)" \
        "V2bX-socks5-linux-amd64.tar.gz#V2bX Socks5 完整安装包" \
        "dist_socks/install_socks.sh#一键安装脚本"

    echo -e "${GREEN}✓ Release 创建成功${NC}"
else
    echo -e "${YELLOW}请手动创建 Release:${NC}"
    echo "1. 访问 https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/new"
    echo "2. Tag version: v1.0.0"
    echo "3. Release title: V2bX Socks5 一键安装版 v1.0.0"
    echo "4. 上传文件:"
    echo "   - V2bX-socks5-linux-amd64.tar.gz"
    echo "   - dist_socks/install_socks.sh"
    echo ""
    read -p "创建完成后按回车继续..."
fi

# 步骤 8: 更新 README 中的链接
echo -e "${YELLOW}[8/8] 更新 README 中的链接...${NC}"
sed -i "s/YOUR_USERNAME/$GITHUB_USERNAME/g" SOCKS5_README.md 2>/dev/null || \
    sed -i '' "s/YOUR_USERNAME/$GITHUB_USERNAME/g" SOCKS5_README.md
sed -i "s/YOUR_USERNAME/$GITHUB_USERNAME/g" DEPLOY_GUIDE.md 2>/dev/null || \
    sed -i '' "s/YOUR_USERNAME/$GITHUB_USERNAME/g" DEPLOY_GUIDE.md

git add SOCKS5_README.md DEPLOY_GUIDE.md
git commit -m "docs: 更新文档中的 GitHub 用户名"
git push

echo -e "${GREEN}✓ 文档链接已更新${NC}"

# 完成
echo ""
echo -e "${GREEN}=== 上传完成! ===${NC}"
echo ""
echo "仓库地址: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo "Release 地址: https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/tag/v1.0.0"
echo ""
echo -e "${GREEN}一键安装命令:${NC}"
echo -e "${YELLOW}bash <(curl -fsSL https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases/download/v1.0.0/install_socks.sh)${NC}"
echo ""
echo "下一步:"
echo "1. 查看 Release 是否正常: https://github.com/$GITHUB_USERNAME/$REPO_NAME/releases"
echo "2. 测试一键安装命令"
echo "3. 在 Linux 服务器上测试对接 XBoard"
echo ""
