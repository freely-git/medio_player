@echo off
chcp 65001 >nul
title 媒体控制台 - 纯净打包与自动清理脚本
echo =======================================================
echo        开始配置纯净隔离环境并打包媒体控制台
echo =======================================================
echo.

:: 1. 创建隔离的虚拟环境
if exist "venv" (
    echo [1/5] 发现已存在的虚拟环境，正在清理后重建...
    rmdir /s /q venv
)
echo [1/5] 正在创建干净的 Python 虚拟环境...
python -m venv venv
if errorlevel 1 (
    echo [错误] 创建虚拟环境失败，请确认已安装 Python 并加入 PATH。
    pause
    exit /b 1
)

:: 2. 激活虚拟环境
call venv\Scripts\activate

:: 3. 安装依赖（强制官方 PyPI，与软件内一键更新同源）
echo.
echo [2/5] 正在连接官方 PyPI，安装依赖...
python -m pip install --upgrade pip -i https://pypi.org/simple/
if errorlevel 1 (
    echo [错误] pip 升级失败。
    pause
    exit /b 1
)

pip install -i https://pypi.org/simple/ ^
    PySide6 ^
    python-vlc ^
    pyinstaller ^
    Pillow ^
    yt-dlp ^
    google-api-python-client ^
    google-auth-httplib2 ^
    google-auth-oauthlib

if errorlevel 1 (
    echo [错误] 依赖安装失败，请检查网络后重试。
    pause
    exit /b 1
)

:: 4. 开始打包
echo.
echo [3/5] 开始执行 PyInstaller 打包...
:: --collect-all yt_dlp：把 yt-dlp 子模块一并打进包，避免漏模块
:: 首次运行用内置版本；之后用户可在设置里一键从官方 PyPI 更新到本地目录
pyinstaller --noconfirm ^
            --windowed ^
            --onefile ^
            --name "MediaConsole" ^
            --icon="iii.png" ^
            --add-data="iii.png;." ^
            --collect-all yt_dlp ^
            --hidden-import yt_dlp ^
            --hidden-import googleapiclient ^
            --hidden-import googleapiclient.discovery ^
            --hidden-import google.auth ^
            --hidden-import google_auth_oauthlib ^
            "媒体播放器_最终版_串联播放_录音版.py"

if errorlevel 1 (
    echo [错误] 打包失败，请向上滚动查看 PyInstaller 报错。
    pause
    exit /b 1
)

:: 5. 清理
echo.
echo [4/5] 正在整理输出文件...
call venv\Scripts\deactivate.bat 2>nul

if not exist "dist\MediaConsole.exe" (
    echo [错误] 未找到 dist\MediaConsole.exe，打包可能未成功。
    pause
    exit /b 1
)

move /y "dist\MediaConsole.exe" "%~dp0MediaConsole.exe" >nul

echo [5/5] 正在清理临时文件和虚拟环境...
rmdir /s /q build 2>nul
rmdir /s /q dist 2>nul
del /f /q MediaConsole.spec 2>nul
rmdir /s /q venv 2>nul

echo.
echo =======================================================
echo 打包与清理任务全部完成！
echo =======================================================
echo 独立软件已生成：%~dp0MediaConsole.exe
echo.
echo 使用说明（发给别人时也可一并说明）：
echo 1. 对方电脑需安装 VLC（python-vlc 依赖系统 VLC）。
echo 2. 若要用 Google 网盘上传，请把 credentials.json 和 exe 放同一目录。
echo 3. YouTube 解析库可在软件「设置 → 检查官方更新」中一键升级，
echo    对方无需安装 Python / pip。
echo.
pause