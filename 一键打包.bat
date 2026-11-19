@echo off
chcp 65001 >nul
echo ========================================
echo    随手账 App - 一键打包 APK
echo ========================================
echo.
echo 本脚本会自动找到已安装的 Flutter 工具链并编译出 APK。
echo 前提：本机已安装 Flutter SDK + Android Studio + JDK 17。
echo.

set JAVA_HOME=C:\Users\YD\toolchain\jdk-17
set ANDROID_HOME=C:\Users\YD\toolchain\android-sdk
set ANDROID_SDK_ROOT=C:\Users\YD\toolchain\android-sdk
set PATH=C:\Users\YD\toolchain\flutter\bin;%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%
set PUB_HOSTED_URL=https://pub.flutter-io.cn
set FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

cd /d "%~dp0"

echo [1/3] 拉取依赖...
call flutter pub get
if errorlevel 1 goto :fail

echo [2/3] 检查代码...
call flutter analyze

echo [3/3] 编译 APK（这一步首次运行较慢，请耐心等待）...
call flutter build apk --release
if errorlevel 1 goto :fail

echo.
echo ========================================
echo  打包成功！
echo  APK 位置：build\app\outputs\flutter-apk\app-release.apk
echo ========================================
explorer "%~dp0build\app\outputs\flutter-apk"
goto :end

:fail
echo.
echo 打包失败，请把上方红色错误信息发给开发者排查。

:end
pause
