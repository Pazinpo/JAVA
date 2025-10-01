# Spring Hello API

간단한 Spring Boot REST API입니다.

## API 엔드포인트

### GET /hello
한국 시간, 타임스탬프, Hello World 메시지를 반환합니다.

**응답 예시:**
```json
{
  "koreaTime": "2025-09-30T15:58:50.972057829+09:00[Asia/Seoul]",
  "timestamp": 1759215530972,
  "message": "Hello, World!"
}
```

## 실행 방법

```bash
mvn spring-boot:run
```

또는

```bash
mvn clean package
java -jar target/spring-hello-api-0.0.1-SNAPSHOT.jar
```

## 테스트

```bash
curl http://localhost:8080/hello
```