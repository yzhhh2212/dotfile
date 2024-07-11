#!/bin/bash

# 检查参数是否传入
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 ip:port"
    exit 1
fi

# 获取 IP 和端口
new_proxy="http://$1/"
new_proxy2="http://$1"

# 确认是否有 /etc/environment 的写权限
if [ ! -w /etc/environment ]; then
    echo "Error: You do not have permission to modify /etc/environment."
    echo "Please run this script as root or with sudo."
    exit 1
fi

# 备份原始文件
sudo cp /etc/environment /etc/environment.bak

# 定义一个函数用于更新或添加代理设置
update_or_add_proxy() {
    local key=$1
    local value="\"$new_proxy\""
    local file=/etc/environment

    # 检查文件中是否存在相应的键
    if grep -q "^$key=" "$file"; then
        # 如果存在，则替换
        sudo sed -i "s|^$key=.*|$key=$value|g" "$file"
    else
        # 如果不存在，则添加
        echo "$key=$value" | sudo tee -a "$file" > /dev/null
    fi
}

update_chrome_proxy() {
    local file="/usr/share/applications/google-chrome.desktop"
    local new_proxy_server="--proxy-server=\"$new_proxy2\""

    # 确认文件存在并且有写权限
    if [ ! -w "$file" ]; then
        echo "Error: You do not have permission to modify $file."
        echo "Please run this script as root or with sudo."
        exit 1
    fi

    # 备份原始文件
    sudo cp "$file" "$file.bak"

    # 更新包含 '--proxy-server' 的行
    sudo sed -i "s|Exec=/usr/bin/google-chrome-stable --proxy-server=\"http://.*\"|Exec=/usr/bin/google-chrome-stable $new_proxy_server|g" "$file"
    sudo sed -i "s|Exec=/usr/bin/google-chrome-stable %U|Exec=/usr/bin/google-chrome-stable $new_proxy_server %U|g" "$file"
    sudo sed -i "s|Exec=/usr/bin/google-chrome-stable --incognito --proxy-server=\"http://.*\"|Exec=/usr/bin/google-chrome-stable --incognito $new_proxy_server|g" "$file"
    sudo sed -i "s|Exec=/usr/bin/google-chrome-stable --incognito %U|Exec=/usr/bin/google-chrome-stable --incognito $new_proxy_server %U|g" "$file"
}


# 更新代理设置
update_or_add_proxy "HTTP_PROXY" "$new_proxy"
update_or_add_proxy "HTTPS_PROXY" "$new_proxy"
update_or_add_proxy "FTP_PROXY" "$new_proxy"
update_or_add_proxy "ALL_PROXY" "$new_proxy"

update_chrome_proxy

echo "Proxy settings updated successfully."

