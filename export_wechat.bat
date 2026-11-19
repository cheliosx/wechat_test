@echo off
setlocal
set GODOT=C:\Users\PC\Desktop\Godot_v4.7.2\Godot_v4.7.2-stable_win64_console.exe
set OUT=E:\godotProject\wechat_test_wxgame

if not exist "%GODOT%" (
    echo [ERROR] Godot executable not found:
    echo         %GODOT%
    echo         Edit GODOT= in this file.
    pause
    exit /b 1
)

echo === Exporting Godot project to WeChat minigame ===
"%GODOT%" --headless --path "%~dp0." --export-release WeChat
if errorlevel 1 (
    echo.
    echo [FAILED] Export failed, see messages above.
    pause
    exit /b 1
)

echo.
echo [OK] Minigame project updated: %OUT%
echo      Open it in WeChat DevTools and press Compile.
pause
