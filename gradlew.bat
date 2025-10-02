@echo off
REM Windows용 Gradle Wrapper 실행 스크립트
set DIR=%~dp0
if exist "%DIR%gradlew" (
    call "%DIR%gradlew.bat" %*
) else (
    echo gradlew.bat not found!
    exit /b 1
)
