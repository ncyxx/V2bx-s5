#!/bin/bash

set -euo pipefail

SERVICE="V2bX"

show_menu() {
  cat <<'EOF'
V2bX 管理脚本
------------------------------------------
Usage: V2bX <command>

Commands:
  menu         显示本菜单
  start        启动 V2bX
  stop         停止 V2bX
  restart      重启 V2bX
  status       查看运行状态
  enable       设置开机自启
  disable      取消开机自启
  log          查看实时日志
  generate     运行 initconfig.sh 生成配置
  version      查看版本信息
  x25519       生成 X25519 密钥
  install      输出安装提示
  uninstall    停止并移除 V2bX
  update       重新执行在线安装脚本
------------------------------------------
EOF
}

ensure_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "请使用 root 用户执行。"
    exit 1
  fi
}

case "${1:-menu}" in
  menu)
    show_menu
    ;;
  start)
    ensure_root
    systemctl start "${SERVICE}.service"
    ;;
  stop)
    ensure_root
    systemctl stop "${SERVICE}.service"
    ;;
  restart)
    ensure_root
    systemctl restart "${SERVICE}.service"
    ;;
  status)
    systemctl status "${SERVICE}.service"
    ;;
  enable)
    ensure_root
    systemctl enable "${SERVICE}.service"
    ;;
  disable)
    ensure_root
    systemctl disable "${SERVICE}.service"
    ;;
  log)
    journalctl -u "${SERVICE}.service" -e --no-pager -f
    ;;
  generate)
    ensure_root
    /usr/local/V2bX/initconfig.sh
    ;;
  version)
    /usr/local/V2bX/V2bX version
    ;;
  x25519)
    /usr/local/V2bX/V2bX x25519
    ;;
  install)
    echo "请重新运行在线安装脚本：bash <(curl -fsSL ${ASSET_BASE:-https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks}/install_socks.sh)"
    ;;
  uninstall)
    ensure_root
    systemctl stop "${SERVICE}.service" || true
    systemctl disable "${SERVICE}.service" || true
    rm -f /etc/systemd/system/"${SERVICE}.service"
    systemctl daemon-reload
    rm -rf /usr/local/V2bX
    rm -f /usr/bin/V2bX /usr/bin/v2bx
    echo "V2bX 已卸载。"
    ;;
  update)
    ensure_root
    bash <(curl -fsSL "${ASSET_BASE:-https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks}/install_socks.sh") "${2:-}"
    ;;
  *)
    echo "未知命令：$1"
    show_menu
    exit 1
    ;;
esac
