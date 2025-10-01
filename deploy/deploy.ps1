# SCP 배포 스크립트 (PowerShell)
# Spring Boot 애플리케이션을 원격 서버에 배포하는 스크립트

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerHost,
    
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [string]$Port = "22",
    [string]$RemotePath = "/opt/spring-hello-api",
    [string]$KeyFile = "",
    [switch]$Help
)

if ($Help) {
    Write-Host "사용법: .\deploy.ps1 -ServerHost <서버IP> -Username <사용자명> [-Port <포트>] [-RemotePath <원격경로>] [-KeyFile <SSH키파일>]"
    Write-Host ""
    Write-Host "예시:"
    Write-Host "  .\deploy.ps1 -ServerHost 192.168.1.100 -Username ubuntu"
    Write-Host "  .\deploy.ps1 -ServerHost example.com -Username root -Port 2222 -KeyFile ~/.ssh/id_rsa"
    exit 0
}

$AppName = "spring-hello-api"
$JarFile = "..\target\$AppName-0.0.1-SNAPSHOT.jar"
$ConfigFile = "..\src\main\resources\application.properties"

Write-Host "=== Spring Boot SCP 배포 시작 ===" -ForegroundColor Green
Write-Host "대상 서버: $ServerHost" -ForegroundColor Yellow
Write-Host "사용자: $Username" -ForegroundColor Yellow
Write-Host "포트: $Port" -ForegroundColor Yellow
Write-Host "원격 경로: $RemotePath" -ForegroundColor Yellow

# JAR 파일 존재 확인
if (-not (Test-Path $JarFile)) {
    Write-Host "❌ JAR 파일을 찾을 수 없습니다: $JarFile" -ForegroundColor Red
    Write-Host "먼저 'mvn clean package' 명령어로 빌드하세요." -ForegroundColor Red
    exit 1
}

Write-Host "✅ JAR 파일 확인: $JarFile" -ForegroundColor Green

# SSH 연결 테스트
Write-Host "🔗 SSH 연결 테스트 중..." -ForegroundColor Yellow

$SshOptions = "-o ConnectTimeout=10 -o StrictHostKeyChecking=no"
if ($KeyFile) {
    $SshOptions += " -i `"$KeyFile`""
}

$TestConnection = "ssh $SshOptions -p $Port $Username@$ServerHost 'echo Connection successful'"
try {
    Invoke-Expression $TestConnection | Out-Null
    Write-Host "✅ SSH 연결 성공" -ForegroundColor Green
} catch {
    Write-Host "❌ SSH 연결 실패" -ForegroundColor Red
    Write-Host "연결 정보를 확인하고 다시 시도하세요." -ForegroundColor Red
    exit 1
}

# 원격 서버에 애플리케이션 디렉토리 생성
Write-Host "📁 원격 서버에 디렉토리 생성 중..." -ForegroundColor Yellow
$CreateDir = "ssh $SshOptions -p $Port $Username@$ServerHost 'sudo mkdir -p $RemotePath && sudo chown $Username $RemotePath'"
Invoke-Expression $CreateDir

# 기존 애플리케이션 중지
Write-Host "⏹️ 기존 애플리케이션 중지 중..." -ForegroundColor Yellow
$StopApp = "ssh $SshOptions -p $Port $Username@$ServerHost 'pkill -f $AppName || true'"
Invoke-Expression $StopApp

# JAR 파일 복사
Write-Host "📤 JAR 파일 업로드 중..." -ForegroundColor Yellow
$ScpOptions = "-o StrictHostKeyChecking=no"
if ($KeyFile) {
    $ScpOptions += " -i `"$KeyFile`""
}

$CopyJar = "scp $ScpOptions -P $Port `"$JarFile`" $Username@$ServerHost`:$RemotePath/$AppName.jar"
try {
    Invoke-Expression $CopyJar
    Write-Host "✅ JAR 파일 업로드 완료" -ForegroundColor Green
} catch {
    Write-Host "❌ JAR 파일 업로드 실패" -ForegroundColor Red
    exit 1
}

# 설정 파일 복사
if (Test-Path $ConfigFile) {
    Write-Host "📤 설정 파일 업로드 중..." -ForegroundColor Yellow
    $CopyConfig = "scp $ScpOptions -P $Port `"$ConfigFile`" $Username@$ServerHost`:$RemotePath/"
    Invoke-Expression $CopyConfig
    Write-Host "✅ 설정 파일 업로드 완료" -ForegroundColor Green
}

# 시작 스크립트 생성 및 복사
$StartScript = @"
#!/bin/bash
# Spring Boot 애플리케이션 시작 스크립트

APP_NAME="$AppName"
APP_PATH="$RemotePath"
JAR_FILE="`$APP_PATH/`$APP_NAME.jar"
PID_FILE="`$APP_PATH/`$APP_NAME.pid"
LOG_FILE="`$APP_PATH/`$APP_NAME.log"

case `$1 in
    start)
        if [ -f `$PID_FILE ]; then
            echo "애플리케이션이 이미 실행 중입니다. (PID: `$(cat `$PID_FILE))"
            exit 1
        fi
        
        echo "Starting `$APP_NAME..."
        nohup java -jar `$JAR_FILE > `$LOG_FILE 2>&1 &
        echo `$! > `$PID_FILE
        echo "✅ `$APP_NAME 시작됨 (PID: `$(cat `$PID_FILE))"
        echo "로그 확인: tail -f `$LOG_FILE"
        ;;
    stop)
        if [ ! -f `$PID_FILE ]; then
            echo "애플리케이션이 실행되지 않았습니다."
            exit 1
        fi
        
        PID=`$(cat `$PID_FILE)
        echo "Stopping `$APP_NAME (PID: `$PID)..."
        kill `$PID
        rm -f `$PID_FILE
        echo "✅ `$APP_NAME 중지됨"
        ;;
    restart)
        `$0 stop
        sleep 2
        `$0 start
        ;;
    status)
        if [ -f `$PID_FILE ]; then
            PID=`$(cat `$PID_FILE)
            if ps -p `$PID > /dev/null; then
                echo "✅ `$APP_NAME 실행 중 (PID: `$PID)"
            else
                echo "❌ PID 파일은 있지만 프로세스가 실행되지 않음"
                rm -f `$PID_FILE
            fi
        else
            echo "❌ `$APP_NAME 실행되지 않음"
        fi
        ;;
    logs)
        if [ -f `$LOG_FILE ]; then
            tail -f `$LOG_FILE
        else
            echo "로그 파일을 찾을 수 없습니다: `$LOG_FILE"
        fi
        ;;
    *)
        echo "사용법: `$0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
"@

# 임시 스타트 스크립트 파일 생성
$TempStartScript = ".\start-app.sh"
$StartScript | Out-File -FilePath $TempStartScript -Encoding UTF8

# 시작 스크립트 복사
Write-Host "📤 시작 스크립트 업로드 중..." -ForegroundColor Yellow
$CopyStartScript = "scp $ScpOptions -P $Port `"$TempStartScript`" $Username@$ServerHost`:$RemotePath/"
Invoke-Expression $CopyStartScript

# 시작 스크립트 실행 권한 부여
$ChmodScript = "ssh $SshOptions -p $Port $Username@$ServerHost 'chmod +x $RemotePath/start-app.sh'"
Invoke-Expression $ChmodScript

# 임시 파일 삭제
Remove-Item $TempStartScript

Write-Host "✅ 시작 스크립트 업로드 완료" -ForegroundColor Green

# 애플리케이션 시작
Write-Host "🚀 애플리케이션 시작 중..." -ForegroundColor Yellow
$StartApp = "ssh $SshOptions -p $Port $Username@$ServerHost '$RemotePath/start-app.sh start'"
Invoke-Expression $StartApp

Write-Host "" 
Write-Host "=== 배포 완료 ===" -ForegroundColor Green
Write-Host "애플리케이션 URL: http://$ServerHost:8080/hello" -ForegroundColor Yellow
Write-Host ""
Write-Host "원격 서버 명령어:" -ForegroundColor Cyan
Write-Host "  상태 확인: $RemotePath/start-app.sh status" -ForegroundColor White
Write-Host "  로그 확인: $RemotePath/start-app.sh logs" -ForegroundColor White
Write-Host "  애플리케이션 중지: $RemotePath/start-app.sh stop" -ForegroundColor White
Write-Host "  애플리케이션 재시작: $RemotePath/start-app.sh restart" -ForegroundColor White