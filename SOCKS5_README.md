# V2bX Socks5 一键安装版

> 基于 V2bX 的 Socks5 支持版本，支持一键安装和对接 XBoard 面板

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-green.svg)](https://www.linux.org/)

## ✨ 特性

- ✅ **Socks5 协议支持**（基于 Xray 核心）
- ✅ **一键安装脚本**（自动配置环境）
- ✅ **配置向导**（交互式配置）
- ✅ **XBoard 对接**（支持 V2board >= 1.7.0）
- ✅ **多协议支持**（Shadowsocks, Vless, Vmess, Trojan, Hysteria, Tuic, Socks5）
- ✅ **审计规则**（自动屏蔽违规流量）
- ✅ **系统服务**（systemd 管理）

## 🚀 快速开始

### 一键安装

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks/install_socks.sh)
```

或者使用 wget：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks/install_socks.sh)
```

### 手动安装

```bash
# 1. 下载压缩包
wget https://github.com/ncyxx/V2bx-s5/releases/download/v1.0.0/V2bX-socks5-linux-amd64.tar.gz

# 2. 解压
tar -xzf V2bX-socks5-linux-amd64.tar.gz

# 3. 复制文件
sudo mkdir -p /usr/local/V2bX /etc/V2bX
sudo cp V2bX-linux-amd64 /usr/local/V2bX/V2bX
sudo cp config.json /etc/V2bX/
sudo chmod +x /usr/local/V2bX/V2bX

# 4. 运行配置向导
sudo bash initconfig.sh
```

## 📋 配置 XBoard

### 前置准备

1. **XBoard 面板地址**：`http://your-xboard.com`
2. **API Key**：在 XBoard 后台获取
3. **节点 ID**：在 XBoard 创建节点后获得

### 配置步骤

安装完成后，运行配置向导：

```bash
V2bX generate
```

按照提示输入：

```
请输入机场网址: http://your-xboard.com
请输入面板对接API Key: your-api-key
请选择节点核心类型: 1  (xray)
请输入节点Node ID: 1
请选择节点传输协议: 8  (Socks5)
```

## 🎯 支持的协议

| 协议 | Xray 核心 | Sing-box 核心 |
|------|----------|--------------|
| Shadowsocks | ✅ | ✅ |
| Vless | ✅ | ✅ |
| Vmess | ✅ | ✅ |
| Trojan | ✅ | ✅ |
| Hysteria | ❌ | ✅ |
| Hysteria2 | ❌ | ✅ |
| Tuic | ❌ | ✅ |
| **Socks5** | ✅ | ❌ |

> ⚠️ **注意**: Socks5 协议仅支持 Xray 核心

## 🛠️ 管理命令

```bash
V2bX              # 显示管理菜单（交互式）
V2bX start        # 启动 V2bX 服务
V2bX stop         # 停止 V2bX 服务
V2bX restart      # 重启 V2bX 服务
V2bX status       # 查看运行状态
V2bX log          # 查看实时日志
V2bX enable       # 设置开机自启
V2bX disable      # 取消开机自启
V2bX generate     # 生成/重新生成配置文件
V2bX update       # 更新到最新版本
V2bX uninstall    # 卸载 V2bX
V2bX version      # 查看版本信息
V2bX x25519       # 生成 x25519 密钥（用于 Reality）
```

## 📁 配置文件位置

```
/etc/V2bX/
├── config.json              # 主配置文件
├── custom_inbound.json      # Socks5 入站配置
├── custom_outbound.json     # 出站配置
├── dns.json                 # DNS 配置
├── route.json               # 路由规则（含审计）
├── geoip.dat                # 地理位置数据
└── geosite.dat              # 网站分类数据
```

## 🔧 自定义配置

### 修改 Socks5 端口

编辑 `/etc/V2bX/custom_inbound.json`：

```json
{
    "listen": "0.0.0.0",
    "port": 1234,  // ← 修改为你需要的端口
    "protocol": "socks",
    "settings": {
        "auth": "noauth",
        "udp": false
    }
}
```

修改后重启服务：

```bash
V2bX restart
```

### 启用 Socks5 认证

修改 `/etc/V2bX/custom_inbound.json`：

```json
{
    "settings": {
        "auth": "password",  // ← 改为 password
        "accounts": [
            {
                "user": "your-username",
                "pass": "your-password"
            }
        ]
    }
}
```

## 📊 系统要求

| 项目 | 要求 |
|------|------|
| **操作系统** | CentOS 7+, Ubuntu 16+, Debian 8+ |
| **权限** | Root 用户 |
| **内存** | 最低 256MB，推荐 512MB+ |
| **磁盘** | 最低 100MB |
| **架构** | x86_64 (amd64), ARM64 |
| **XBoard 版本** | >= 1.7.0 |

## 🐛 故障排查

### 服务无法启动

```bash
# 查看详细日志
V2bX log

# 检查配置文件语法
cat /etc/V2bX/config.json | python -m json.tool

# 检查端口占用
netstat -tlnp | grep 1234
```

### 无法连接 XBoard

```bash
# 检查网络连接
curl -I http://your-xboard.com

# 查看 API 对接日志
V2bX log | grep -i api

# 检查配置文件中的 ApiHost 和 ApiKey
cat /etc/V2bX/config.json | grep -E "ApiHost|ApiKey"
```

### 流量不通

```bash
# 检查防火墙
firewall-cmd --list-ports  # CentOS
ufw status                 # Ubuntu

# 开放端口
firewall-cmd --permanent --add-port=1234/tcp  # CentOS
ufw allow 1234/tcp                            # Ubuntu
```

## 📖 完整文档

详细的部署和配置文档请参考：[DEPLOY_GUIDE.md](./DEPLOY_GUIDE.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目基于 [InazumaV/V2bX](https://github.com/InazumaV/V2bX) 修改。

原项目许可证: [LICENSE](./LICENSE)

## ⚠️ 免责声明

- 本项目仅供学习交流使用
- 请遵守当地法律法规
- 不得用于非法用途
- 使用本项目造成的任何后果由使用者自行承担

## 🙏 致谢

- [InazumaV/V2bX](https://github.com/InazumaV/V2bX) - 原始项目
- [Project X](https://github.com/XTLS/) - Xray 核心
- [sing-box](https://github.com/SagerNet/sing-box) - Sing-box 核心

---

**📮 联系方式**

- GitHub Issues: [提交问题](https://github.com/ncyxx/V2bx-s5/issues)
- Telegram: @YourTelegramGroup

---

<p align="center">
  Made with ❤️ for XBoard users
</p>
