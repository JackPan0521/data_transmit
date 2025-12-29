# Flutter Windows 建置自動化腳本
# 自動處理建置、CMake 修復和文件複製

Write-Host "🚀 開始 Windows 建置流程..." -ForegroundColor Cyan

# 1. 修復 Firebase CMake 版本（如果文件存在）
$cmakeFile = "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
if (Test-Path $cmakeFile) {
    Write-Host "🔧 修復 Firebase CMake 版本..." -ForegroundColor Yellow
    $content = Get-Content $cmakeFile -Raw
    $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.14)'
    $content | Set-Content $cmakeFile -NoNewline
    Write-Host "✓ CMake 版本已更新" -ForegroundColor Green
}

# 2. 執行 Flutter 建置
Write-Host "🔨 建置 Windows Release 版本..." -ForegroundColor Yellow
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 建置失敗" -ForegroundColor Red
    
    # 嘗試修復並重新建置
    if (Test-Path $cmakeFile) {
        Write-Host "🔧 重新修復 CMake 並再次建置..." -ForegroundColor Yellow
        $content = Get-Content $cmakeFile -Raw
        $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.14)'
        $content | Set-Content $cmakeFile -NoNewline
        
        flutter build windows --release
    }
}

# 3. 複製必要的文件
$source = "C:\Program Files\data_transmit"
$dest = "build\windows\x64\runner\Release"

if (Test-Path $source) {
    Write-Host "📦 複製所有必要文件..." -ForegroundColor Yellow
    Copy-Item "$source\*" -Destination $dest -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✓ 文件複製完成" -ForegroundColor Green
} else {
    Write-Host "⚠️  警告: Program Files 中的文件不存在，跳過複製" -ForegroundColor Yellow
}

# 4. 驗證建置結果
$exePath = "$dest\data_transmit.exe"
$dllPath = "$dest\flutter_windows.dll"

Write-Host "`n📊 建置結果:" -ForegroundColor Cyan
if (Test-Path $exePath) {
    $exe = Get-Item $exePath
    Write-Host "✓ 可執行檔: $exePath" -ForegroundColor Green
    Write-Host "  大小: $([math]::Round($exe.Length/1MB, 2)) MB" -ForegroundColor Gray
    Write-Host "  更新時間: $($exe.LastWriteTime)" -ForegroundColor Gray
} else {
    Write-Host "❌ 可執行檔不存在" -ForegroundColor Red
}

if (Test-Path $dllPath) {
    Write-Host "✓ Flutter DLL: 已就緒" -ForegroundColor Green
} else {
    Write-Host "❌ Flutter DLL 缺失" -ForegroundColor Red
}

# 5. 詢問是否啟動應用
Write-Host "`n" -NoNewline
$response = Read-Host "是否要啟動應用程式？(Y/N)"
if ($response -eq 'Y' -or $response -eq 'y') {
    if (Test-Path $exePath) {
        Write-Host "🚀 啟動應用程式..." -ForegroundColor Cyan
        Start-Process $exePath
    } else {
        Write-Host "❌ 無法啟動：可執行檔不存在" -ForegroundColor Red
    }
}

Write-Host "`n✅ 建置流程完成！" -ForegroundColor Green
