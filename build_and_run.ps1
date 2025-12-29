# 快速建置並運行腳本

Write-Host "🚀 快速建置並運行..." -ForegroundColor Cyan

# 修復 CMake（如果需要）
$cmakeFile = "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
if (Test-Path $cmakeFile) {
    $content = Get-Content $cmakeFile -Raw
    if ($content -match 'cmake_minimum_required\(VERSION 3\.1\)') {
        $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.14)'
        $content | Set-Content $cmakeFile -NoNewline
        Write-Host "✓ CMake 已修復" -ForegroundColor Green
    }
}

# 建置
flutter build windows --release

# 複製文件
$source = "C:\Program Files\data_transmit"
$dest = "build\windows\x64\runner\Release"
if (Test-Path $source) {
    Copy-Item "$source\*" -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ 文件已複製" -ForegroundColor Green
}

# 運行
$exePath = "$dest\data_transmit.exe"
if (Test-Path $exePath) {
    Write-Host "🚀 啟動應用..." -ForegroundColor Cyan
    Start-Process $exePath
} else {
    Write-Host "❌ 建置失敗" -ForegroundColor Red
}
