# Windows 建置指南

## 🚀 快速開始

### 方法 1：使用自動化腳本（推薦）

**完整建置流程：**

```powershell
.\build_windows.ps1
```

**快速建置並運行：**

```powershell
.\build_and_run.ps1
```

### 方法 2：手動建置

如果腳本無法執行，請手動執行以下步驟：

#### 步驟 1：修復 Firebase CMake

```powershell
# 如果文件存在，修改 CMakeLists.txt
$file = "build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace 'cmake_minimum_required\(VERSION 3\.1\)', 'cmake_minimum_required(VERSION 3.14)'
    $content | Set-Content $file -NoNewline
}
```

#### 步驟 2：建置

```powershell
flutter build windows --release
```

#### 步驟 3：複製文件

```powershell
Copy-Item "C:\Program Files\data_transmit\*" -Destination "build\windows\x64\runner\Release\" -Recurse -Force
```

#### 步驟 4：運行

```powershell
Start-Process "build\windows\x64\runner\Release\data_transmit.exe"
```

## ⚠️ 常見問題

### 腳本無法執行

如果 PowerShell 腳本無法執行，請以管理員身份運行 PowerShell 並執行：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### CMake 錯誤

如果出現 CMake 版本錯誤，建置腳本會自動修復。如果自動修復失敗，手動修改：

- 文件：`build\windows\x64\extracted\firebase_cpp_sdk_windows\CMakeLists.txt`
- 第 17 行：將 `VERSION 3.1` 改為 `VERSION 3.14`

### DLL 缺失錯誤

建置完成後會自動複製所有必要的 DLL。如果手動建置，記得執行步驟 3。

## 📦 建置產物

成功建置後，可執行檔位於：

```
build\windows\x64\runner\Release\data_transmit.exe
```

完整應用程式需要的文件：

- `data_transmit.exe` - 主程式
- `flutter_windows.dll` - Flutter 引擎
- `data/` - 資源文件夾
- `*.lib` - Plugin 程式庫

## 🎯 建議的開發流程

### 日常開發測試

使用 Web 版本（快速啟動）：

```powershell
flutter run -d chrome
```

### Windows 版本測試

使用自動化腳本：

```powershell
.\build_and_run.ps1
```

### 發布版本

使用完整建置腳本：

```powershell
.\build_windows.ps1
```
