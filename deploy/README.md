# Spring Boot SCP 전통 배포 가이드

## 개요
이 가이드는 Spring Boot 애플리케이션을 SCP(Secure Copy Protocol)를 사용하여 원격 서버에 전통적인 방식으로 배포하는 방법을 설명합니다.

## 프로젝트 정보
- **프로젝트명**: spring-hello-api
- **GitHub 저장소**: https://github.com/Pazinpo/JAVA.git
- **포트**: 8080
- **엔드포인트**: `/hello`

## 사전 요구사항

### 로컬 환경
- ✅ Java 11+ 설치
- ✅ Maven 설치 및 PATH 설정
- ✅ SSH 클라이언트 (Windows PowerShell 기본 제공)

### 원격 서버
- ✅ Linux 서버 (Ubuntu/CentOS 등)
- ✅ Java Runtime Environment (JRE) 11+ 설치
- ✅ SSH 서버 실행 중
- ✅ 방화벽에서 8080 포트 오픈

## 배포 방법

### 1. 간단한 배포 (권장)
```powershell
# deploy 디렉토리로 이동
cd deploy

# 빌드 + 배포를 한번에
.\manage.ps1 deploy -ServerHost <서버IP> -Username <사용자명>

# 예시
.\manage.ps1 deploy -ServerHost 192.168.1.100 -Username ubuntu
```

### 2. 단계별 배포

#### Step 1: 애플리케이션 빌드
```powershell
# 방법 1: 관리 스크립트 사용
cd deploy
.\manage.ps1 build

# 방법 2: 직접 Maven 사용
mvn clean package
```

#### Step 2: 서버에 배포
```powershell
cd deploy
.\deploy.ps1 -ServerHost <서버IP> -Username <사용자명>

# SSH 키 파일 사용시
.\deploy.ps1 -ServerHost <서버IP> -Username <사용자명> -KeyFile "C:\Users\사용자\.ssh\id_rsa"

# 다른 포트 사용시
.\deploy.ps1 -ServerHost <서버IP> -Username <사용자명> -Port 2222
```

## 원격 서버 관리

### PowerShell 관리 스크립트 사용
```powershell
cd deploy

# 애플리케이션 상태 확인
.\manage.ps1 status -ServerHost <서버IP> -Username <사용자명>

# 실시간 로그 확인
.\manage.ps1 logs -ServerHost <서버IP> -Username <사용자명>

# 애플리케이션 중지
.\manage.ps1 stop -ServerHost <서버IP> -Username <사용자명>

# 애플리케이션 재시작
.\manage.ps1 restart -ServerHost <서버IP> -Username <사용자명>
```

### 직접 SSH 명령어 사용
```bash
# 서버에 SSH 접속
ssh username@server-ip

# 애플리케이션 상태 확인
/opt/spring-hello-api/start-app.sh status

# 애플리케이션 시작
/opt/spring-hello-api/start-app.sh start

# 애플리케이션 중지
/opt/spring-hello-api/start-app.sh stop

# 애플리케이션 재시작
/opt/spring-hello-api/start-app.sh restart

# 실시간 로그 확인 (Ctrl+C로 종료)
/opt/spring-hello-api/start-app.sh logs

# 또는 직접 로그 파일 확인
tail -f /opt/spring-hello-api/spring-hello-api.log
```

## 배포 구조

### 로컬 파일 구조
```
spring-hello-api/
├── src/
├── target/
│   └── spring-hello-api-0.0.1-SNAPSHOT.jar  # 빌드된 JAR
├── deploy/
│   ├── deploy.ps1      # SCP 배포 스크립트
│   └── manage.ps1      # 통합 관리 스크립트
└── pom.xml
```

### 원격 서버 파일 구조
```
/opt/spring-hello-api/
├── spring-hello-api.jar     # 실행 파일
├── application.properties   # 설정 파일
├── start-app.sh            # 시작/중지 스크립트
├── spring-hello-api.pid     # 프로세스 ID 파일
└── spring-hello-api.log     # 애플리케이션 로그
```

## 배포 프로세스

1. **빌드**: Maven으로 실행 가능한 JAR 파일 생성
2. **연결 테스트**: SSH 연결 상태 확인
3. **기존 앱 중지**: 실행 중인 애플리케이션 종료
4. **파일 업로드**: JAR, 설정 파일, 시작 스크립트 복사
5. **권한 설정**: 실행 권한 부여
6. **애플리케이션 시작**: 백그라운드에서 실행

## 접속 확인

배포가 완료되면 웹 브라우저에서 다음 URL로 접속하여 확인:

```
http://<서버IP>:8080/hello
```

예상 응답:
```json
{
  "koreaTime": "2025-10-01T...",
  "timestamp": 1727...,
  "message": "Hello, World!"
}
```

## 트러블슈팅

### 자주 발생하는 문제

#### 1. Maven 명령어를 찾을 수 없음
```
해결책: Maven 설치 후 시스템 PATH에 추가하고 새 PowerShell 세션 시작
```

#### 2. SSH 연결 실패
```
해결책: 
- 서버 IP 주소 확인
- SSH 포트 확인 (기본값: 22)
- 방화벽 설정 확인
- SSH 키 권한 확인 (600)
```

#### 3. 포트 8080 접속 불가
```
해결책:
- 서버 방화벽에서 8080 포트 오픈
- 애플리케이션 실행 상태 확인
- 로그 파일에서 오류 메시지 확인
```

#### 4. 권한 부족 오류
```
해결책:
- sudo 권한이 있는 사용자 사용
- 배포 디렉토리 권한 확인
- 필요시 chown으로 소유권 변경
```

## 보안 고려사항

1. **SSH 키 사용**: 비밀번호 대신 SSH 키 인증 권장
2. **방화벽 설정**: 필요한 포트만 오픈
3. **사용자 권한**: 최소 권한 원칙 적용
4. **로그 모니터링**: 정기적인 로그 확인

## 추가 기능

### 환경별 설정 관리
다른 환경(개발/스테이징/프로덕션)을 위해 `application-{profile}.properties` 파일을 생성하고 다음과 같이 실행:

```bash
java -jar -Dspring.profiles.active=production spring-hello-api.jar
```

### 시스템 서비스 등록
애플리케이션을 시스템 서비스로 등록하려면:

```bash
sudo cp /opt/spring-hello-api/start-app.sh /etc/init.d/spring-hello-api
sudo update-rc.d spring-hello-api defaults
```

## 지원

- **GitHub 이슈**: https://github.com/Pazinpo/JAVA/issues
- **문서 개선**: Pull Request 환영

---
**작성일**: 2025-10-01  
**버전**: 1.0.0