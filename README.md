# V2bX Socks5 版本

> 基于 V2bX 的 Socks5 扩展版本，支持一键安装和 XBoard 面板对接

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub release](https://img.shields.io/github/v/release/ncyxx/V2bx-s5)](https://github.com/ncyxx/V2bx-s5/releases)
[![Platform](https://img.shields.io/badge/Platform-Linux-green.svg)](https://www.linux.org/)

## 🚀 快速安装

### 一键安装（推荐）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks/install_socks.sh)
```

或使用 wget：

```bash
bash <(wget -qO- https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks/install_socks.sh)
```

### CDN 加速安装（国内推荐）

```bash
bash <(curl -fsSL https://cdn.jsdelivr.net/gh/ncyxx/V2bx-s5@main/dist_socks/install_socks.sh)
```

## ✨ 主要特性

- ✅ **Socks5 协议支持** - 基于 Xray 核心实现
- ✅ **一键安装脚本** - 自动配置系统环境
- ✅ **配置向导** - 交互式配置，简单易用
- ✅ **XBoard 对接** - 完美支持 V2board >= 1.7.0
- ✅ **多协议支持** - Shadowsocks, Vless, Vmess, Trojan, Hysteria, Tuic, Socks5
- ✅ **审计规则** - 自动屏蔽违规流量
- ✅ **Systemd 服务** - 开机自启，稳定运行

## 🎯 支持的协议

| 协议 | Xray 核心 | Sing-box 核心 | 状态 |
|------|----------|--------------|------|
| Shadowsocks | ✅ | ✅ | 稳定 |
| Vless | ✅ | ✅ | 稳定 |
| Vmess | ✅ | ✅ | 稳定 |
| Trojan | ✅ | ✅ | 稳定 |
| Hysteria | ❌ | ✅ | 稳定 |
| Hysteria2 | ❌ | ✅ | 稳定 |
| Tuic | ❌ | ✅ | 稳定 |
| **Socks5** | ✅ | ❌ | **新增** |

> ⚠️ **注意**: Socks5 协议仅支持 Xray 核心

## 📖 使用文档

- [快速开始指南](./SOCKS5_README.md) - Socks5 功能详细说明
- [完整部署文档](./DEPLOY_GUIDE.md) - 从上传到部署的完整教程

## 🛠️ 配置 XBoard

### 1. 运行安装脚本

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks/install_socks.sh)
```

### 2. 填写配置信息

安装完成后，按提示输入：

```
机场网址: http://your-xboard.com
API Key: your-api-key
节点核心: 1 (xray)
节点 ID: 1
传输协议: 8 (Socks5)
```

### 3. 服务管理

```bash
V2bX start        # 启动服务
V2bX stop         # 停止服务
V2bX restart      # 重启服务
V2bX status       # 查看状态
V2bX log          # 查看日志
V2bX generate     # 重新生成配置
```

## 📊 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | CentOS 7+, Ubuntu 16+, Debian 8+ |
| 权限 | Root 用户 |
| 内存 | 最低 256MB，推荐 512MB+ |
| 磁盘 | 最低 100MB |
| 架构 | x86_64, ARM64 |
| XBoard 版本 | >= 1.7.0 |

## 🔧 常用命令

```bash
# 管理菜单
V2bX

# 服务管理
V2bX start          # 启动
V2bX stop           # 停止
V2bX restart        # 重启
V2bX status         # 状态

# 配置管理
V2bX generate       # 生成配置
V2bX log            # 查看日志
V2bX version        # 版本信息

# 系统管理
V2bX enable         # 开机自启
V2bX disable        # 取消自启
V2bX update         # 更新版本
V2bX uninstall      # 卸载
```

## 📁 配置文件

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

## 🐛 故障排查

### 查看日志

```bash
V2bX log
```

### 检查服务状态

```bash
V2bX status
systemctl status V2bX
```

### 测试配置文件

```bash
cat /etc/V2bX/config.json | python -m json.tool
```

### 检查端口占用

```bash
netstat -tlnp | grep 1234
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

- 报告问题: [GitHub Issues](https://github.com/ncyxx/V2bx-s5/issues)
- 提交代码: [Pull Requests](https://github.com/ncyxx/V2bx-s5/pulls)

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
- 所有贡献者

## 📮 联系方式

- GitHub: [@ncyxx](https://github.com/ncyxx)
- Issues: [提交问题](https://github.com/ncyxx/V2bx-s5/issues)

---

<p align="center">
  <b>⭐ 如果这个项目对您有帮助，请给个 Star!</b>
</p>
