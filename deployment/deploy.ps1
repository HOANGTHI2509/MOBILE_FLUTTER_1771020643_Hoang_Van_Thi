# Deploy Script to VPS
$VPS_IP = "103.77.172.159"
$VPS_USER = "root"
$REMOTE_PATH = "/var/www/pcm-backend"
$LOCAL_PROJECT_PATH = "..\PcmBackend"

Write-Host "=== BƯỚC 1: Build & Publish Backend ===" -ForegroundColor Green
dotnet publish $LOCAL_PROJECT_PATH -c Release -o .\publish
if ($LASTEXITCODE -ne 0) { Write-Error "Build thất bại!"; exit }

Write-Host "=== BƯỚC 2: Upload Files (Sẽ yêu cầu nhập Password) ===" -ForegroundColor Yellow
# Tạo thư mục trên VPS nếu chưa có
ssh ${VPS_USER}@${VPS_IP} "mkdir -p ${REMOTE_PATH}"

# Upload file setup và config trước
scp .\setup_vps.sh ${VPS_USER}@${VPS_IP}:/root/setup_vps.sh
scp .\docker-compose.yml ${VPS_USER}@${VPS_IP}:/root/docker-compose.yml
scp .\pcm-backend.service ${VPS_USER}@${VPS_IP}:/etc/systemd/system/pcm-backend.service

# Upload publish files
Write-Host "Uploading application files..."
scp -r .\publish\* ${VPS_USER}@${VPS_IP}:${REMOTE_PATH}

Write-Host "=== BƯỚC 3: Restart Service (Sẽ yêu cầu nhập Password) ===" -ForegroundColor Yellow
ssh ${VPS_USER}@${VPS_IP} "systemctl daemon-reload && systemctl enable pcm-backend && systemctl restart pcm-backend"

Write-Host "=== HOÀN TẤT! ===" -ForegroundColor Green
Write-Host "API sẽ có tại: http://${VPS_IP}:5000"
Write-Host "Hãy SSH vào VPS và chạy './setup_vps.sh' nếu đây là lần đầu tiên deploy."
