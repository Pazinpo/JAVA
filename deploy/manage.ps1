# 로컬 관리 스크립트 (PowerShell)
# 빌드, 배포, 원격 서버 관리를 위한 통합 스크립트

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("build", "deploy", "status", "logs", "stop", "restart", "help")]
    [string]$Action,
    
    [string]$ServerHost = "",
    [string]$Username = "",
    [string]$Port = "22",
    [string]$KeyFile = ""
)

$AppName = "spring-hello-api"
$RemotePath = "/opt/spring-hello-api"

function Show-Help {
    Write-Host "Spring Boot SCP 배포 관리 도구" -ForegroundColor Green
    Write-Host ""
    Write-Host "사용법:" -ForegroundColor Yellow
    Write-Host "  .\manage.ps1 build                                    # 로컬 빌드"
    Write-Host "  .\manage.ps1 deploy -ServerHost <IP> -Username <사용자> # 배포"
    Write-Host "  .\manage.ps1 status -ServerHost <IP> -Username <사용자> # 상태 확인"
    Write-Host "  .\manage.ps1 logs -ServerHost <IP> -Username <사용자>  # 로그 확인"
    Write-Host "  .\manage.ps1 stop -ServerHost <IP> -Username <사용자>  # 애플리케이션 중지"
    Write-Host "  .\manage.ps1 restart -ServerHost <IP> -Username <사용자># 애플리케이션 재시작"
    Write-Host ""
    Write-Host "옵션:" -ForegroundColor Yellow
    Write-Host "  -Port <포트>      SSH 포트 (기본값: 22)"
    Write-Host "  -KeyFile <경로>   SSH 키 파일 경로"
    Write-Host ""
    Write-Host "예시:" -ForegroundColor Cyan
    Write-Host "  .\manage.ps1 build"
    Write-Host "  .\manage.ps1 deploy -ServerHost 192.168.1.100 -Username ubuntu"
    Write-Host "  .\manage.ps1 status -ServerHost example.com -Username root -Port 2222"
}

function Build-Application {
    Write-Host "=== 애플리케이션 빌드 시작 ===" -ForegroundColor Green
    
    # Maven 실행 가능 여부 확인
    try {
        $MavenVersion = mvn --version 2>$null
        if ($?) {
            Write-Host "✅ Maven 발견" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Maven을 찾을 수 없습니다." -ForegroundColor Red
        Write-Host "Maven을 설치하고 PATH에 추가한 후 다시 시도하세요." -ForegroundColor Red
        return $false
    }
    
    # 프로젝트 루트로 이동
    Push-Location ..
    
    try {
        Write-Host "🔨 Maven 빌드 실행 중..." -ForegroundColor Yellow
        mvn clean package -DskipTests
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ 빌드 성공!" -ForegroundColor Green
            
            # JAR 파일 확인
            $JarFile = "target\$AppName-0.0.1-SNAPSHOT.jar"
            if (Test-Path $JarFile) {
                $FileInfo = Get-Item $JarFile
                Write-Host "📦 생성된 JAR: $JarFile ($([math]::Round($FileInfo.Length/1MB, 2)) MB)" -ForegroundColor Green
                return $true
            } else {
                Write-Host "⚠️ JAR 파일을 찾을 수 없습니다." -ForegroundColor Yellow
                return $false
            }
        } else {
            Write-Host "❌ 빌드 실패" -ForegroundColor Red
            return $false
        }
    }
    finally {
        Pop-Location
    }
}

function Execute-RemoteCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    if (-not $ServerHost -or -not $Username) {
        Write-Host "❌ ServerHost와 Username이 필요합니다." -ForegroundColor Red
        return $false
    }
    
    Write-Host "🔗 $Description..." -ForegroundColor Yellow
    
    $SshOptions = "-o ConnectTimeout=10 -o StrictHostKeyChecking=no"
    if ($KeyFile) {
        $SshOptions += " -i `"$KeyFile`""
    }
    
    $FullCommand = "ssh $SshOptions -p $Port $Username@$ServerHost '$Command'"
    try {
        Invoke-Expression $FullCommand
        return $true
    } catch {
        Write-Host "❌ 원격 명령 실행 실패: $Command" -ForegroundColor Red
        return $false
    }
}

# 메인 로직
switch ($Action) {
    "build" {
        Build-Application
    }
    
    "deploy" {
        if (-not $ServerHost -or -not $Username) {
            Write-Host "❌ 배포를 위해서는 -ServerHost와 -Username이 필요합니다." -ForegroundColor Red
            Show-Help
            exit 1
        }
        
        # 먼저 빌드
        if (Build-Application) {
            Write-Host ""
            Write-Host "🚀 배포 시작..." -ForegroundColor Green
            
            $DeployArgs = "-ServerHost $ServerHost -Username $Username -Port $Port"
            if ($KeyFile) {
                $DeployArgs += " -KeyFile `"$KeyFile`""
            }
            
            $DeployCommand = ".\deploy.ps1 $DeployArgs"
            Invoke-Expression $DeployCommand
        } else {
            Write-Host "❌ 빌드가 실패하여 배포를 중단합니다." -ForegroundColor Red
            exit 1
        }
    }
    
    "status" {
        Execute-RemoteCommand "$RemotePath/start-app.sh status" "애플리케이션 상태 확인"
    }
    
    "logs" {
        Write-Host "📋 실시간 로그 확인 (Ctrl+C로 종료)" -ForegroundColor Yellow
        Execute-RemoteCommand "$RemotePath/start-app.sh logs" "로그 확인"
    }
    
    "stop" {
        Execute-RemoteCommand "$RemotePath/start-app.sh stop" "애플리케이션 중지"
    }
    
    "restart" {
        Execute-RemoteCommand "$RemotePath/start-app.sh restart" "애플리케이션 재시작"
    }
    
    "help" {
        Show-Help
    }
}