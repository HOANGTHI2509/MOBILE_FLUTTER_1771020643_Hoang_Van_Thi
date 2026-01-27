# PCM Backend & Frontend Startup Script
# Chạy file này để khởi động cả Backend và Frontend cùng lúc

Write-Host "🚀 Starting PCM System..." -ForegroundColor Green

# 1. Start Backend
Write-Host "`n📡 Starting Backend API..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\PcmBackend'; Write-Host '🔧 Backend running on http://localhost:5282' -ForegroundColor Green; dotnet run"

# Wait for backend to start
Start-Sleep -Seconds 5

# 2. Start Frontend
Write-Host "`n🎨 Starting Flutter App..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PSScriptRoot\pcm_mobile_643'; Write-Host '📱 Flutter app starting...' -ForegroundColor Green; flutter run -d chrome --web-browser-flag '--disable-web-security' --web-browser-flag '--user-data-dir=C:/tmp/pcm_chrome_session'"

Write-Host "`n✅ System started successfully!" -ForegroundColor Green
Write-Host "Backend: http://localhost:5282" -ForegroundColor Yellow
Write-Host "Frontend: Will open in Chrome automatically" -ForegroundColor Yellow
Write-Host "`nPress any key to exit this window..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
