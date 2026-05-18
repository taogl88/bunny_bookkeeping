# Claude Code 项目配置

## Android 开发环境

### Flutter SDK
- 路径: `E:\terminal\flutter-sdk\bin\flutter`
- Windows 命令: `E:\code\jizhang>` 调用

### adb (Android Debug Bridge)
- 路径: `D:\AndroidSDK\platform-tools\adb.exe`
- 完整命令: `/d/AndroidSDK/platform-tools/adb.exe`

## 项目结构
- 项目路径: `E:\code\jizhang`
- APK 输出: `build\app\outputs\flutter-apk\app-debug.apk`

## 常用命令

### 构建并安装（不卸载数据）
```bash
# 查找设备
flutter devices

# 安装到模拟器
flutter install --debug --device-id emulator-5554
```

### 使用 adb 安装（保留数据）
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 模拟器
- 名称: `ledger_api34` / `sdk gphone64 x86 64`
- 设备 ID: `emulator-5554`

## 操作指南
硬性规定：执行完需求后自动编译、构建、保留数据安装到模拟器、启动app前台运行