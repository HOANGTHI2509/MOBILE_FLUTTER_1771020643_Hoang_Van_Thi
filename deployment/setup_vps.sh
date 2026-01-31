#!/bin/bash
# setup_vps.sh - Script cài đặt môi trường trên VPS Ubuntu 22.04
# Chạy với quyền root: sudo ./setup_vps.sh

set -e # D dừng nếu có lỗi

echo "=== CẬP NHẬT HỆ THỐNG ==="
apt-get update && apt-get upgrade -y
apt-get install -y curl wget unzip git nginx gnupg2

echo "=== CÀI ĐẶT DOCKER & DOCKER COMPOSE ==="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    rm get-docker.sh
else 
    echo "Docker đã được cài đặt."
fi

# Cài Docker Compose Plugin (v2) - Mặc định đi kèm docker hiện đại
# Nếu cần standalone compose (v1): apt install docker-compose -y

echo "=== CÀI ĐẶT .NET 8.0 SDK & RUNTIME ==="
# Add Microsoft repo
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
apt-get update
apt-get install -y dotnet-sdk-8.0 aspnetcore-runtime-8.0

echo "=== CẤU HÌNH FIREWALL (UFW) ==="
ufw allow OpenSSH
ufw allow 'Nginx Full'
# ufw allow 1433/tcp # Chỉ mở nếu muốn connect SQL từ xa (Không khuyến nghị)
ufw --force enable

echo "=== Setup hoàn tất! Vui lòng logout và login lại để nhận permission Docker. ==="
echo "Tiếp theo: Copy docker-compose.yml vào thư mục app và chạy 'docker compose up -d' để khởi động DB."
