# Quick Backend Restart Script
# Sử dụng khi cần restart backend nhanh

Write-Host "🔄 Restarting Backend..." -ForegroundColor Yellow

# Kill existing dotnet processes (if any)
Get-Process dotnet -ErrorAction SilentlyContinue | Where-Object {$_.Path -like "*BKT_Mobile*"} | Stop-Process -Force

Write-Host "✅ Old processes stopped" -ForegroundColor Green

# Start backend
cd "$PSScriptRoot\PcmBackend"
Write-Host "🚀 Starting Backend on http://localhost:5282" -ForegroundColor Cyan
dotnet run
