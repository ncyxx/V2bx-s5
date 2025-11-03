#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

[[ $EUID -ne 0 ]] && echo -e "${red}错误：${plain}必须使用 root 用户运行此脚本。\n" && exit 1

detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        release="centos"
    elif grep -Eqi "debian" /etc/issue; then
        release="debian"
    elif grep -Eqi "ubuntu" /etc/issue; then
        release="ubuntu"
    elif grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux" /etc/issue; then
        release="centos"
    elif grep -Eqi "debian" /proc/version; then
        release="debian"
    elif grep -Eqi "ubuntu" /proc/version; then
        release="ubuntu"
    elif grep -Eqi "centos|red hat|redhat|rocky|alma|oracle linux" /proc/version; then
        release="centos"
    else
        echo -e "${red}未检测到支持的系统版本，请联系脚本作者。${plain}"
        exit 1
    fi
}

detect_arch() {
    arch=$(arch)
    case "$arch" in
        x86_64 | x64 | amd64)
            arch="64"
            ;;
        aarch64 | arm64)
            arch="arm64-v8a"
            ;;
        s390x)
            arch="s390x"
            ;;
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
    fi

    if [[ x"${release}" == x"centos" ]]; then
        [[ ${os_version} -le 6 ]] && echo -e "${red}请使用 CentOS 7 或以上版本。${plain}" && exit 1
    elif [[ x"${release}" == x"ubuntu" ]]; then
        [[ ${os_version} -lt 16 ]] && echo -e "${red}请使用 Ubuntu 16 或以上版本。${plain}" && exit 1
    elif [[ x"${release}" == x"debian" ]]; then
        [[ ${os_version} -lt 8 ]] && echo -e "${red}请使用 Debian 8 或以上版本。${plain}" && exit 1
    fi
}

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
        yum install ca-certificates wget -y
        update-ca-trust force-enable
    else
        apt-get update -y
        apt-get install -y wget curl unzip tar cron socat ca-certificates
        update-ca-certificates
    fi
}

latest_release_tag() {
    local repo="${RELEASE_REPO:-InazumaV/V2bX}"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
        | grep '"tag_name":' \
        | sed -E 's/.*"([^"]+)".*/\1/'
}

download_release() {
    local version="$1"
    local repo="${RELEASE_REPO:-InazumaV/V2bX}"
    local url="https://github.com/${repo}/releases/download/${version}/V2bX-linux-${arch}.zip"
    wget -q -N --no-check-certificate -O /usr/local/V2bX/V2bX-linux.zip "${url}"
}

install_socks_assets() {
    cat <<'EOF' >/usr/local/V2bX/custom_inbound.json
[
    {
        "listen": "0.0.0.0",
        "port": 1234,
        "protocol": "socks",
        "settings": {
            "auth": "noauth",
            "accounts": [
                {
                    "user": "my-username",
                    "pass": "my-password"
                }
            ],
            "udp": false,
            "ip": "127.0.0.1",
            "userLevel": 0
        }
    }
]
EOF

    cat <<'EOF' >/usr/local/V2bX/initconfig.sh
#!/bin/bash
# 一键配置

add_node_config() {
    echo -e "${green}请选择节点核心类型：${plain}"
    echo -e "${green}1. xray${plain}"
    echo -e "${green}2. singbox${plain}"
    read -rp "请输入：" core_type
    if [ "$core_type" == "1" ]; then
        core="xray"
        core_xray=true
    elif [ "$core_type" == "2" ]; then
        core="sing"
        core_sing=true
    else
        echo "无效的选择。请选择 1 或 2。"
        continue
    fi
    while true; do
        read -rp "请输入节点Node ID：" NodeID
        if [[ "$NodeID" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "错误：请输入正确的数字作为Node ID。"
        fi
    done

    echo -e "${yellow}请选择节点传输协议：${plain}"
    echo -e "${green}1. Shadowsocks${plain}"
    echo -e "${green}2. Vless${plain}"
    echo -e "${green}3. Vmess${plain}"
    echo -e "${green}4. Hysteria${plain}"
    echo -e "${green}5. Hysteria2${plain}"
    echo -e "${green}6. Tuic${plain}"
    echo -e "${green}7. Trojan${plain}"
    echo -e "${green}8. Socks5${plain}"
    read -rp "请输入：" NodeType
    case "$NodeType" in
        1 ) NodeType="shadowsocks" ;;
        2 ) NodeType="vless" ;;
        3 ) NodeType="vmess" ;;
        4 ) NodeType="hysteria" ;;
        5 ) NodeType="hysteria2" ;;
        6 ) NodeType="tuic" ;;
        7 ) NodeType="trojan" ;;
        8 ) NodeType="socks" ;;
        * ) NodeType="shadowsocks" ;;
    esac

    if [ "$NodeType" = "socks" ] && [ "$core" != "xray" ]; then
        echo -e "${yellow}Socks5 节点仅支持 Xray 核心，已自动切换为 Xray${plain}"
        core="xray"
        core_xray=true
        core_sing=false
    fi

    enable_uot="true"
    if [ "$NodeType" = "socks" ]; then
        enable_uot="false"
    fi
    nodes_config+=(
        {
            \"Core\": \"$core\",
            \"ApiHost\": \"$ApiHost\",
            \"ApiKey\": \"$ApiKey\",
            \"NodeID\": $NodeID,
            \"NodeType\": \"$NodeType\",
            \"Timeout\": 4,
            \"ListenIP\": \"0.0.0.0\",
            \"SendIP\": \"0.0.0.0\",
            \"EnableProxyProtocol\": false,
            \"EnableUot\": $enable_uot,
            \"EnableTFO\": true,
            \"DNSType\": \"UseIPv4\"
        }
    )
    nodes_config+=(",")
}

generate_config_file() {
    echo -e "${yellow}V2bX 配置文件生成向导${plain}"
    echo -e "${red}请阅读以下注意事项：${plain}"
    echo -e "${red}1. 目前该功能正处测试阶段${plain}"
    echo -e "${red}2. 生成的配置文件会保存到 /etc/V2bX/config.json${plain}"
    echo -e "${red}3. 原来的配置文件会保存到 /etc/V2bX/config.json.bak${plain}"
    echo -e "${red}4. 目前不支持TLS${plain}"
    echo -e "${red}5. 使用此功能生成的配置文件会自带审计，确定继续?(y/n)${plain}"
    read -rp "请输入：" continue_prompt
    if [[ "$continue_prompt" =~ ^[Nn][Oo]? ]]; then
        exit 0
    fi

    nodes_config=()
    first_node=true
    core_xray=false
    core_sing=false
    fixed_api_info=false
    check_api=false

    while true; do
        if [ "$first_node" = true ]; then
            read -rp "请输入机场网址：" ApiHost
            read -rp "请输入面板对接API Key：" ApiKey
            read -rp "是否设置固定的机场网址和API Key?(y/n)" fixed_api
            if [ "$fixed_api" = "y" ] || [ "$fixed_api" = "Y" ]; then
                fixed_api_info=true
                echo -e "${red}成功固定地址${plain}"
            fi
            first_node=false
            add_node_config
        else
            read -rp "是否继续添加节点配置?(回车继续，输入n或no退出)" continue_adding_node
            if [[ "$continue_adding_node" =~ ^[Nn][Oo]? ]]; then
                break
            elif [ "$fixed_api_info" = false ]; then
                read -rp "请输入机场网址：" ApiHost
                read -rp "请输入面板对接API Key：" ApiKey
            fi
            add_node_config
        fi
    done

    if [ "$core_xray" = true ] && [ "$core_sing" = true ]; then
        cores_config="[
        {
            \"Type\": \"xray\",
            \"Log\": {
                \"Level\": \"error\",
                \"ErrorPath\": \"/etc/V2bX/error.log\"
            },
            \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
            \"RouteConfigPath\": \"/etc/V2bX/route.json\"
        },
        {
            \"Type\": \"sing\",
            \"Log\": {
                \"Level\": \"error\",
                \"Timestamp\": true
            },
            \"DnsConfigPath\": \"/etc/V2bX/dns.json\",
            \"NTP\": {
                \"Enable\": true,
                \"Server\": \"time.apple.com\",
                \"ServerPort\": 0
            }
        }
        ]"
    elif [ "$core_xray" = true ]; then
        cores_config="[
        {
            \"Type\": \"xray\",
            \"Log\": {
                \"Level\": \"error\",
                \"ErrorPath\": \"/etc/V2bX/error.log\"
            },
            \"OutboundConfigPath\": \"/etc/V2bX/custom_outbound.json\",
            \"RouteConfigPath\": \"/etc/V2bX/route.json\"
        }
        ]"
    elif [ "$core_sing" = true ]; then
        cores_config="[
        {
            \"Type\": \"sing\",
            \"Log\": {
                \"Level\": \"error\",
                \"Timestamp\": true
            },
            \"DnsConfigPath\": \"/etc/V2bX/dns.json\",
            \"NTP\": {
                \"Enable\": true,
                \"Server\": \"time.apple.com\",
                \"ServerPort\": 0
            }
        }
        ]"
    else
        echo -e "${red}未选择任何核心，生成配置文件失败。${plain}"
        exit 1
    fi

    cd /etc/V2bX
    mv config.json config.json.bak
    formatted_nodes_config=$(echo "${nodes_config[*]}" | sed 's/,\s*$//')

    cat <<EOF > /etc/V2bX/config.json
    {
        "Log": {
            "Level": "error",
            "Output": ""
        },
        "Cores": $cores_config,
        "Nodes": [$formatted_nodes_config]
    }
EOF

    cat <<EOF > /etc/V2bX/custom_outbound.json
    [
        {
            "tag": "IPv4_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv4"
            }
        },
        {
            "tag": "IPv6_out",
            "protocol": "freedom",
            "settings": {
                "domainStrategy": "UseIPv6"
            }
        },
        {
            "tag": "direct",
            "protocol": "freedom"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
EOF

    cat <<EOF > /etc/V2bX/route.json
    {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "geoip:private",
                    "58.87.70.69"
                ]
            },
            {
                "type": "field",
                "outboundTag": "direct",
                "domain": [
                    "domain:zgovps.com"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "domain": [
                    "regexp:(api|ps|sv|offnavi|newvector|ulog.imap|newloc)(.map|).(baidu|n.shifen).com",
                    "regexp:(.+.|^)(360|so).(cn|com)",
                    "regexp:(Subject|HELO|SMTP)",
                    "regexp:(torrent|.torrent|peer_id=|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=)",
                    "regexp:(^.@)(guerrillamail|guerrillamailblock|sharklasers|grr|pokemail|spam4|bccto|chacuo|027168).(info|biz|com|de|net|org|me|la)",
                    "regexp:(.?)(xunlei|sandai|Thunder|XLLiveUD)(.)",
                    "regexp:(..||)(dafahao|mingjinglive|botanwang|minghui|dongtaiwang|falunaz|epochtimes|ntdtv|falundafa|falungong|wujieliulan|zhengjian).(org|com|net)",
                    "regexp:(ed2k|.torrent|peer_id=|announce|info_hash|get_peers|find_node|BitTorrent|announce_peer|announce.php?passkey=|magnet:|xunlei|sandai|Thunder|XLLiveUD|bt_key)",
                    "regexp:(.+.|^)(360|speedtest|fast).(cn|com|net)",
                    "regexp:(.*.||)(guanjia.qq.com|qqpcmgr|QQPCMGR)",
                    "regexp:(.*.||)(rising|kingsoft|duba|xindubawukong|jinshanduba).(com|net|org)",
                    "regexp:(.*.||)(netvigator|torproject).(com|cn|net|org)",
                    "regexp:(..||)(visa|mycard|gov|gash|beanfun|bank).",
                    "regexp:(.*.||)(gov|12377|12315|talk.news.pts.org|creaders|zhuichaguoji|efcc.org|cyberpolice|aboluowang|tuidang|epochtimes|nytimes|zhengjian|110.qq|mingjingnews|inmediahk|xinsheng|breakgfw|chengmingmag|jinpianwang|qi-gong|mhradio|edoors|renminbao|soundofhope|xizang-zhiye|bannedbook|ntdtv|12321|secretchina|dajiyuan|boxun|chinadigitaltimes|dwnews|huaglad|oneplusnews|epochweekly|cn.rfi).(cn|com|org|net|club|net|fr|tw|hk|eu|info|me)",
                    "regexp:(.*.||)(miaozhen|cnzz|talkingdata|umeng).(cn|com)",
                    "regexp:(.*.||)(mycard).(com|tw)",
                    "regexp:(.*.||)(gash).(com|tw)",
                    "regexp:(.bank.)",
                    "regexp:(.*.||)(pincong).(rocks)",
                    "regexp:(.*.||)(taobao).(com)",
                    "regexp:(.*.||)(laomoe|jiyou|ssss|lolicp|vv1234|0z|4321q|868123|ksweb|mm126).(com|cloud|fun|cn|gs|xyz|cc)",
                    "regexp:(flows|miaoko).(pages).(dev)"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "ip": [
                    "127.0.0.1/32",
                    "10.0.0.0/8",
                    "fc00::/7",
                    "fe80::/10",
                    "172.16.0.0/12"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "protocol": [
                    "bittorrent"
                ]
            },
            {
                "type": "field",
                "outboundTag": "block",
                "port": "23,24,25,107,194,445,465,587,992,3389,6665-6669,6679,6697,6881-6999,7000"
            }
        ]
    }
EOF

    echo -e "${green}V2bX 配置文件生成完成,正在重新启动服务${plain}"
    v2bx restart
}

install_bbr() {
    bash <(curl -L -s https://github.com/ylx2016/Linux-NetSpeed/raw/master/tcpx.sh)
}
EOF
    chmod +x /usr/local/V2bX/initconfig.sh

    if [[ ! -f /etc/V2bX/custom_inbound.json ]]; then
        cp /usr/local/V2bX/custom_inbound.json /etc/V2bX/custom_inbound.json
    fi
}

install_V2bX() {
    local specified_version="$1"
    if [[ -e /usr/local/V2bX/ ]]; then
        rm -rf /usr/local/V2bX/
    fi

    mkdir -p /usr/local/V2bX/
    cd /usr/local/V2bX/

    local version
    if [[ -z "$specified_version" ]]; then
        version=$(latest_release_tag)
        if [[ -z "$version" ]]; then
            echo -e "${red}获取 V2bX 版本失败，请稍后再试或手动指定版本。${plain}"
            exit 1
        fi
        echo -e "检测到最新版本：${version}，开始安装。"
    else
        version="$specified_version"
        echo -e "开始安装 V2bX ${version}"
    fi

    download_release "${version}"
    if [[ $? -ne 0 ]]; then
        echo -e "${red}下载 V2bX 失败，请确认网络访问 Github 正常或指定正确版本。${plain}"
        exit 1
    fi

    unzip -q V2bX-linux.zip
    rm -f V2bX-linux.zip
    chmod +x V2bX
    install_socks_assets

    mkdir -p /etc/V2bX/
    rm -f /etc/systemd/system/V2bX.service
    wget -q -N --no-check-certificate -O /etc/systemd/system/V2bX.service https://github.com/InazumaV/V2bX-script/raw/master/V2bX.service
    systemctl daemon-reload
    systemctl stop V2bX >/dev/null 2>&1
    systemctl enable V2bX
    echo -e "${green}V2bX ${version}${plain} 安装完成，已设置开机自启。"

    cp geoip.dat /etc/V2bX/
    cp geosite.dat /etc/V2bX/

    if [[ ! -f /etc/V2bX/config.json ]]; then
        cp config.json /etc/V2bX/
        first_install=true
    else
        systemctl start V2bX
        sleep 2
        if systemctl is-active --quiet V2bX; then
            echo -e "${green}V2bX 重启成功${plain}"
        else
            echo -e "${red}V2bX 可能启动失败，请使用 V2bX log 查看日志信息。${plain}"
        fi
        first_install=false
    fi

    if [[ ! -f /etc/V2bX/dns.json ]]; then
        cp dns.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/route.json ]]; then
        cp route.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/V2bX/
    fi
    if [[ ! -f /etc/V2bX/custom_inbound.json ]]; then
        cp custom_inbound.json /etc/V2bX/
    fi

    curl -o /usr/bin/V2bX -Ls https://raw.githubusercontent.com/InazumaV/V2bX-script/master/V2bX.sh
    chmod +x /usr/bin/V2bX
    if [[ ! -L /usr/bin/v2bx ]]; then
        ln -s /usr/bin/V2bX /usr/bin/v2bx
        chmod +x /usr/bin/v2bx
    fi

    cd "$cur_dir"
    rm -f install_socks.sh

    echo -e ""
    echo "V2bX 管理脚本使用方法："
    echo "------------------------------------------"
    echo "V2bX              - 显示管理菜单"
    echo "V2bX start        - 启动 V2bX"
    echo "V2bX stop         - 停止 V2bX"
    echo "V2bX restart      - 重启 V2bX"
    echo "V2bX status       - 查看 V2bX 状态"
    echo "V2bX enable       - 设置 V2bX 开机自启"
    echo "V2bX disable      - 取消 V2bX 开机自启"
    echo "V2bX log          - 查看 V2bX 日志"
    echo "V2bX x25519       - 生成 x25519 密钥"
    echo "V2bX generate     - 生成 V2bX 配置文件"
    echo "V2bX update       - 更新 V2bX"
    echo "V2bX update x.x.x - 更新指定版本"
    echo "V2bX install      - 安装 V2bX"
    echo "V2bX uninstall    - 卸载 V2bX"
    echo "V2bX version      - 查看版本"
    echo "------------------------------------------"

    if [[ $first_install == true ]]; then
        read -rp "检测到为首次安装，是否立即生成配置文件?(y/n): " if_generate
        if [[ $if_generate == [Yy] ]]; then
            source /usr/local/V2bX/initconfig.sh
            generate_config_file
            read -rp "是否安装 BBR 内核?(y/n): " if_install_bbr
            if [[ $if_install_bbr == [Yy] ]]; then
                install_bbr
            fi
        fi
    fi
}

echo -e "${green}开始安装${plain}"
detect_os
detect_arch
check_bits
check_os_version
install_base
install_V2bX "$1"
