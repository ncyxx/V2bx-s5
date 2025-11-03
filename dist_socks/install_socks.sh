#!/bin/bash

set -euo pipefail

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

ASSET_BASE_DEFAULT="https://raw.githubusercontent.com/ncyxx/V2bx-s5/main/dist_socks"
RELEASE_REPO_DEFAULT="ncyxx/V2bx-s5"

ASSET_BASE="${ASSET_BASE:-$ASSET_BASE_DEFAULT}"
RELEASE_REPO="${RELEASE_REPO:-$RELEASE_REPO_DEFAULT}"

cur_dir=$(pwd)

[[ $EUID -ne 0 ]] && {
  echo -e "${red}错误：${plain}必须使用 root 用户运行此脚本。"
  exit 1
}

download_asset() {
  local name=$1
  local dest=$2
  if ! curl -fsSL "${ASSET_BASE}/${name}" -o "${dest}"; then
    echo -e "${red}下载 ${name} 失败，请检查 ASSET_BASE 设置或网络。${plain}"
    exit 1
  fi
}

detect_os() {
  if [[ -f /etc/redhat-release ]]; then
    release="centos"
  elif grep -Eqi "debian" /etc/issue >/dev/null 2>&1; then
    release="debian"
  elif grep -Eqi "ubuntu" /etc/issue >/dev/null 2>&1; then
    release="ubuntu"
  elif grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux" /etc/issue >/dev/null 2>&1; then
    release="centos"
  elif grep -Eqi "debian" /proc/version >/dev/null 2>&1; then
    release="debian"
  elif grep -Eqi "ubuntu" /proc/version >/dev/null 2>&1; then
    release="ubuntu"
  elif grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux" /proc/version >/dev/null 2>&1; then
    release="centos"
  else
    echo -e "${red}未检测到支持的系统版本，请联系脚本作者。${plain}"
    exit 1
  }
}

detect_arch() {
  arch=$(arch)
  case "$arch" in
    x86_64 | x64 | amd64) arch="64" ;;
    aarch64 | arm64) arch="arm64-v8a" ;;
    s390x) arch="s390x" ;;
    *)
      arch="64"
      echo -e "${yellow}未识别的架构，默认使用：${arch}${plain}"
      ;;
  esac
}

check_bits() {
  if [[ "$(getconf WORD_BIT)" != "32" ]] && [[ "$(getconf LONG_BIT)" != "64" ]]; then
    echo -e "${red}本软件不支持 32 位系统 (x86)，请使用 64 位系统。${plain}"
    exit 2
  fi
}

check_os_version() {
  if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
  elif [[ -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
  else
    os_version=""
  fi

  if [[ x"${release}" == x"centos" ]]; then
    [[ -n "$os_version" && ${os_version} -le 6 ]] && {
      echo -e "${red}请使用 CentOS 7 或以上版本。${plain}"
      exit 1
    }
  elif [[ x"${release}" == x"ubuntu" ]]; then
    [[ -n "$os_version" && ${os_version} -lt 16 ]] && {
      echo -e "${red}请使用 Ubuntu 16 或以上版本。${plain}"
      exit 1
    }
  elif [[ x"${release}" == x"debian" ]]; then
    [[ -n "$os_version" && ${os_version} -lt 8 ]] && {
      echo -e "${red}请使用 Debian 8 或以上版本。${plain}"
      exit 1
    }
  fi
}

install_base() {
  if [[ x"${release}" == x"centos" ]]; then
    yum install -y epel-release
    yum install -y wget curl unzip tar crontabs socat
    yum install -y ca-certificates
    update-ca-trust force-enable
  else
    apt-get update -y
    apt-get install -y wget curl unzip tar cron socat ca-certificates
    update-ca-certificates
  fi
}

latest_release_tag() {
  curl -fsSL "https://api.github.com/repos/${RELEASE_REPO}/releases/latest" \
    | grep '"tag_name":' \
    | sed -E 's/.*"([^"]+)".*/\1/'
}

download_release() {
  local version="$1"
  local url="https://github.com/${RELEASE_REPO}/releases/download/${version}/V2bX-linux-${arch}.zip"
  if ! wget -q -O /usr/local/V2bX/V2bX-linux.zip --no-check-certificate "${url}"; then
    echo -e "${red}下载 V2bX 发行包失败 (${url})，请确认版本和仓库。${plain}"
    exit 1
  fi
}

install_socks_assets() {
  mkdir -p /usr/local/V2bX
  mkdir -p /etc/V2bX

  download_asset "custom_inbound.json" "/usr/local/V2bX/custom_inbound.json"
  download_asset "initconfig.sh" "/usr/local/V2bX/initconfig.sh"
  download_asset "custom_outbound.json" "/usr/local/V2bX/custom_outbound.json"
  download_asset "route.json" "/usr/local/V2bX/route.json"
  download_asset "dns.json" "/usr/local/V2bX/dns.json"

  chmod +x /usr/local/V2bX/initconfig.sh

  for file in custom_inbound.json custom_outbound.json route.json dns.json; do
    [[ ! -f "/etc/V2bX/${file}" ]] && cp "/usr/local/V2bX/${file}" "/etc/V2bX/${file}"
  done
}

install_service_files() {
  download_asset "V2bX.service" "/etc/systemd/system/V2bX.service"
  systemctl daemon-reload
  systemctl stop V2bX >/dev/null 2>&1 || true
  systemctl enable V2bX >/dev/null 2>&1

  download_asset "V2bX.sh" "/usr/bin/V2bX"
  chmod +x /usr/bin/V2bX
  if [[ ! -L /usr/bin/v2bx ]]; then
    ln -s /usr/bin/V2bX /usr/bin/v2bx
    chmod +x /usr/bin/v2bx
  fi
}

install_V2bX() {
  local specified_version="${1:-}"

  rm -rf /usr/local/V2bX
  mkdir -p /usr/local/V2bX
  cd /usr/local/V2bX

  local version
  if [[ -z "$specified_version" ]]; then
    version=$(latest_release_tag)
    if [[ -z "$version" ]]; then
      echo -e "${red}获取 V2bX 最新版本失败，请稍后重试或手动指定版本。${plain}"
      exit 1
    fi
    echo -e "检测到最新版本：${version}，开始下载。"
  else
    version="$specified_version"
    echo -e "开始安装 V2bX ${version}"
  fi

  download_release "${version}"
  unzip -q V2bX-linux.zip
  rm -f V2bX-linux.zip
  chmod +x V2bX

  install_socks_assets

  cp geoip.dat /etc/V2bX/
  cp geosite.dat /etc/V2bX/
  [[ ! -f /etc/V2bX/config.json ]] && cp config.json /etc/V2bX/

  install_service_files

  systemctl start V2bX
  sleep 2
  if systemctl is-active --quiet V2bX; then
    echo -e "${green}V2bX 启动成功。${plain}"
  else
    echo -e "${yellow}V2bX 可能启动失败，请运行 'V2bX log' 查看日志。${plain}"
  fi

  cd "${cur_dir}"
}

show_help() {
  cat <<'EOF'
V2bX 管理脚本使用方法：
------------------------------------------
V2bX              - 显示管理菜单
V2bX start        - 启动 V2bX
V2bX stop         - 停止 V2bX
V2bX restart      - 重启 V2bX
V2bX status       - 查看 V2bX 状态
V2bX enable       - 设置 V2bX 开机自启
V2bX disable      - 取消 V2bX 开机自启
V2bX log          - 查看 V2bX 日志
V2bX x25519       - 生成 x25519 密钥
V2bX generate     - 生成 V2bX 配置文件
V2bX update       - 更新 V2bX
V2bX update x.x.x - 更新指定版本
V2bX install      - 安装 V2bX
V2bX uninstall    - 卸载 V2bX
V2bX version      - 查看 V2bX 版本
------------------------------------------
EOF
}

prompt_generate_config() {
  if [[ ! -f /etc/V2bX/config.json ]] || [[ ! -s /etc/V2bX/config.json ]]; then
    echo -ne "${yellow}检测到为首次安装，是否立即生成配置文件?(y/n): ${plain}"
    read -r if_generate
    if [[ $if_generate =~ ^[Yy]$ ]]; then
      /usr/local/V2bX/initconfig.sh
    fi
  fi
}

echo -e "${green}开始安装${plain}"
detect_os
detect_arch
check_bits
check_os_version
install_base
install_V2bX "${1:-}"
show_help
prompt_generate_config
