# V2bX Socks5 一键安装部署指南

## 📋 目录
1. [上传到 GitHub](#1-上传到-github)
2. [创建 GitHub Release](#2-创建-github-release)
3. [一键安装命令](#3-一键安装命令)
4. [配置到 XBoard](#4-配置到-xboard)

---

## 1. 上传到 GitHub

### 方式 A: Fork 并创建自己的仓库（推荐）

#### 步骤 1: Fork 原仓库或创建新仓库

**选项 1: 在 GitHub 网页操作**
1. 访问 https://github.com
2. 点击右上角 "+" → "New repository"
3. 填写仓库名称，例如: `V2bx-s5`
4. 选择 Public（公开）或 Private（私有）
5. 点击 "Create repository"

**选项 2: 使用 GitHub CLI**
```bash
# 安装 GitHub CLI (如果未安装)
# Windows: winget install GitHub.cli
# 或访问 https://cli.github.com/

# 登录 GitHub
gh auth login

# 创建新仓库
gh repo create V2bx-s5 --public --source=. --remote=origin
```

#### 步骤 2: 更新 .gitignore（忽略大文件）

由于 GitHub 限制单个文件最大 100MB，我们需要忽略编译好的二进制文件：

```bash
cd "/d/project/gui/书屋OBS源码C++开源/AmtoOBS/V2bX"

# 添加到 .gitignore
echo "" >> .gitignore
echo "# 忽略编译产物和大文件" >> .gitignore
echo "V2bX-linux-amd64" >> .gitignore
echo "V2bx-s5-linux-amd64.tar.gz" >> .gitignore
echo "*.tar.gz" >> .gitignore
echo "dist_socks/*.tar.gz" >> .gitignore
```

#### 步骤 3: 提交更改到本地仓库

```bash
cd "/d/project/gui/书屋OBS源码C++开源/AmtoOBS/V2bX"

# 查看当前状态
git status

# 添加新增的 Socks5 相关文件
git add core/xray/socks.go
git add dist_socks/
git add .gitignore

# 添加修改的文件
git add api/panel/node.go
git add api/panel/panel.go
git add core/sing/node.go
git add core/xray/inbound.go
git add core/xray/user.go
git add core/xray/xray.go

# 提交到本地
git commit -m "feat: 添加 Socks5 支持和一键安装脚本

- 新增 Socks5 协议支持
- 添加 dist_socks 一键安装包
- 包含配置向导脚本 initconfig.sh
- 支持 XBoard 面板对接"
```

#### 步骤 4: 推送到 GitHub

**如果是新创建的仓库：**
```bash
# 添加远程仓库（将 ncyxx 替换为你的 GitHub 用户名）
git remote remove origin  # 移除原来的 origin
git remote add origin https://github.com/ncyxx/V2bx-s5.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

**如果是 Fork 的仓库：**
```bash
# 直接推送到你的 Fork
git push origin main
```

---

## 2. 创建 GitHub Release

### 方式 A: 使用 GitHub 网页创建 Release

#### 步骤 1: 上传大文件到 Release

1. 访问你的仓库页面: `https://github.com/ncyxx/V2bx-s5`
2. 点击右侧 "Releases" → "Create a new release"
3. 填写信息：
   - **Tag version**: `v1.0.0` 或 `v1.0.0-socks5`
   - **Release title**: `V2bX Socks5 一键安装版 v1.0.0`
   - **Description**:
     ```markdown
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
     ```bash
     wget -O install.sh https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh
     chmod +x install.sh
     bash install.sh
     ```

     或使用一键命令：
     ```bash
     bash <(curl -fsSL https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh)
     ```

     ### 系统要求
     - CentOS 7+ / Ubuntu 16+ / Debian 8+
     - 需要 root 权限
     - V2board >= 1.7.0
     ```

4. 上传附件：
   - 将 `V2bx-s5-linux-amd64.tar.gz` 拖拽到附件区域
   - 将 `dist_socks/install_socks.sh` 重命名并上传

5. 点击 "Publish release"

### 方式 B: 使用 GitHub CLI 创建 Release

```bash
cd "/d/project/gui/书屋OBS源码C++开源/AmtoOBS/V2bX"

# 创建 Release 并上传文件
gh release create v1.0.0 \
  --title "V2bX Socks5 一键安装版 v1.0.0" \
  --notes "支持 Socks5 协议的一键安装版本" \
  V2bx-s5-linux-amd64.tar.gz \
  dist_socks/install_socks.sh
```

---

## 3. 一键安装命令

### 创建安装脚本 URL

安装脚本将托管在 GitHub Release 中，用户可以通过以下方式安装：

#### 方式 1: 下载后安装（推荐）
```bash
# 下载安装脚本
wget -O install.sh https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh

# 赋予执行权限
chmod +x install.sh

# 运行安装
sudo bash install.sh
```

#### 方式 2: 一键安装（curl）
```bash
bash <(curl -fsSL https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh)
```

#### 方式 3: 一键安装（wget）
```bash
bash <(wget -qO- https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh)
```

### 修改安装脚本指向你的 Release

编辑 `dist_socks/install_socks.sh`，修改下载链接：

```bash
# 在 download_release 函数中（约第 95-100 行）
download_release() {
    local version="$1"
    local repo="${RELEASE_REPO:-ncyxx/V2bx-s5}"  # ← 修改这里
    local url="https://github.com/${repo}/releases/download/${version}/V2bx-s5-linux-amd64.tar.gz"  # ← 修改文件名
    wget -q -N --no-check-certificate -O /usr/local/V2bX/V2bX-linux.tar.gz "${url}"
}
```

---

## 4. 配置到 XBoard

### 前置要求

1. **XBoard 面板** 已部署（版本 >= 1.7.0）
2. **Linux 服务器** 一台（CentOS 7+ / Ubuntu 16+ / Debian 8+）
3. **API Key** 在 XBoard 后台获取
4. **节点 ID** 在 XBoard 创建节点后获得

### 安装步骤

#### 步骤 1: 运行一键安装脚本

```bash
# SSH 登录到服务器

# 运行一键安装（使用上面的任意方式）
bash <(curl -fsSL https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/install_socks.sh)
```

#### 步骤 2: 配置向导

安装完成后会自动启动配置向导：

```
V2bX 配置文件生成向导
请阅读以下注意事项：
1. 目前该功能正处测试阶段
2. 生成的配置文件会保存到 /etc/V2bX/config.json
3. 原来的配置文件会保存到 /etc/V2bX/config.json.bak
4. 目前不支持TLS
5. 使用此功能生成的配置文件会自带审计，确定继续?(y/n)
```

输入 `y` 继续。

#### 步骤 3: 填写配置信息

```bash
# 1. 输入 XBoard 面板地址
请输入机场网址: http://your-xboard-domain.com

# 2. 输入 API Key（在 XBoard 后台获取）
请输入面板对接API Key: your-api-key-here

# 3. 是否固定 API 信息（多节点时推荐）
是否设置固定的机场网址和API Key?(y/n) y

# 4. 选择核心类型
请选择节点核心类型：
1. xray
2. singbox
请输入: 1  ← Socks5 只能选 xray

# 5. 输入节点 ID（在 XBoard 创建节点后获得）
请输入节点Node ID: 1

# 6. 选择协议类型
请选择节点传输协议：
1. Shadowsocks
2. Vless
3. Vmess
4. Hysteria
5. Hysteria2
6. Tuic
7. Trojan
8. Socks5
请输入: 8  ← 选择 Socks5

# 7. 是否继续添加节点
是否继续添加节点配置?(回车继续，输入n或no退出) n
```

#### 步骤 4: 启动服务

配置完成后自动重启服务：

```bash
# 查看服务状态
V2bX status

# 查看日志
V2bX log

# 如果需要手动重启
V2bX restart
```

### 在 XBoard 中创建 Socks5 节点

1. 登录 XBoard 管理后台
2. 进入 "节点管理" → "添加节点"
3. 填写节点信息：
   - **节点名称**: 自定义，例如 "香港 Socks5 01"
   - **节点类型**: Shadowsocks（或根据面板实际选项）
   - **协议**: Socks5
   - **地址**: 服务器 IP
   - **端口**: 默认 1234（可在 custom_inbound.json 修改）
   - **其他配置**: 根据需要填写
4. 保存后获得 **节点 ID**
5. 使用该节点 ID 配置 V2bX

---

## 5. 管理命令

```bash
V2bX              # 显示管理菜单
V2bX start        # 启动服务
V2bX stop         # 停止服务
V2bX restart      # 重启服务
V2bX status       # 查看状态
V2bX log          # 查看日志
V2bX generate     # 重新生成配置文件
V2bX update       # 更新版本
V2bX uninstall    # 卸载
```

---

## 6. 常见问题

### Q1: GitHub 文件太大无法上传？
**A**: 不要直接提交 104MB 的可执行文件和 40MB 的压缩包，而是：
1. 将它们添加到 `.gitignore`
2. 通过 GitHub Release 上传
3. 修改安装脚本从 Release 下载

### Q2: 如何使用国内镜像加速？
**A**: 可以将文件上传到 Gitee 或使用 jsdelivr CDN：
```bash
# jsdelivr CDN 加速
https://cdn.jsdelivr.net/gh/ncyxx/V2bx-s5@main/dist_socks/install_socks.sh
```

### Q3: 安装失败提示权限不足？
**A**: 需要使用 root 权限：
```bash
sudo bash install.sh
```

### Q4: 如何修改 Socks5 端口？
**A**: 编辑配置文件：
```bash
nano /etc/V2bX/custom_inbound.json
# 修改 "port": 1234 为你需要的端口
V2bX restart
```

### Q5: 如何查看是否成功对接 XBoard？
**A**: 查看日志：
```bash
V2bX log
# 成功对接会显示节点信息和用户数量
```

---

## 7. 安全建议

1. ✅ 修改默认 Socks5 端口（1234）
2. ✅ 启用 Socks5 认证（username/password）
3. ✅ 配置防火墙规则
4. ✅ 定期更新系统和软件
5. ✅ 使用强密码
6. ✅ 启用审计规则（安装脚本已包含）

---

## 8. 贡献与反馈

如有问题或建议，欢迎：
- 提交 Issue: https://github.com/ncyxx/V2bx-s5/issues
- 提交 PR: https://github.com/ncyxx/V2bx-s5/pulls

---

## 许可证

本项目基于原项目 [InazumaV/V2bX](https://github.com/InazumaV/V2bX) 修改。
请遵守原项目的许可证要求。

---

**⚠️ 免责声明**：本项目仅供学习交流使用，请遵守当地法律法规。
