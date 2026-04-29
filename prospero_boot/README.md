# Prospero Boot

CoinDesk API를 활용한 암호화폐 뉴스 조회 Spring Boot 서비스

## 개요

이 서비스는 CoinDesk API를 통해 암호화폐 관련 뉴스를 일 단위로 조회할 수 있는 REST API를 제공합니다.

## 주요 기능

- **날짜별 핫 뉴스 조회**: 특정 날짜의 핫 뉴스를 조회 (yyyyMMdd 형식)
- **최근 핫 뉴스 조회**: 최근 N개의 핫 뉴스를 조회
- **자동 날짜 파싱**: 잘못된 날짜 입력 시 오늘 날짜로 자동 설정
- **구조화된 응답**: JSON 형식의 구조화된 뉴스 데이터 제공

## 시스템 요구사항

- Java 17 이상
- Maven 3.6 이상
- CoinDesk API 키

## 빌드 및 실행

### 빌드

```bash
cd prospero_boot
mvn clean package
```

### 실행

```bash
# API 키는 application.yml에 설정되어 있으므로 직접 실행 가능
mvn spring-boot:run
```

또는

```bash
java -jar target/prospero-boot-1.0.0.jar
```

## API 엔드포인트

### 1. 날짜별 뉴스 조회

**요청**

```bash
GET /api/news/by-date?date=20260429
```

**파라미터**

- `date` (선택): 조회 날짜 (yyyyMMdd 형식, 예: 20260429)
  - 생략 시: 오늘 날짜로 설정

**응답 (성공)**

```json
{
  "date": "20260429",
  "count": 5,
  "news": [
    {
      "id": "news-123",
      "title": "Bitcoin Price Surge",
      "description": "Bitcoin reaches new highs...",
      "url": "https://coindesk.com/news/123",
      "publishedAt": "2026-04-29T10:30:00",
      "source": "CoinDesk",
      "image": "https://example.com/image.jpg",
      "categories": ["Bitcoin", "Markets"]
    }
  ]
}
```

### 2. 최근 뉴스 조회

**요청**

```bash
GET /api/news/latest?limit=30
```

**파라미터**

- `limit` (선택): 조회 건수 (기본값: 30)

**응답 (성공)**

```json
{
  "count": 30,
  "news": [
    {
      "id": "news-456",
      "title": "Ethereum Updates Coming",
      "description": "New Ethereum upgrades...",
      "url": "https://coindesk.com/news/456",
      "publishedAt": "2026-04-29T12:00:00",
      "source": "CoinDesk",
      "image": "https://example.com/image.jpg",
      "categories": ["Ethereum"]
    }
  ]
}
```

## 프로젝트 구조

```
prospero_boot/
├── src/
│   ├── main/
│   │   ├── java/com/prospero/
│   │   │   ├── ProsperoBootApplication.java    # 메인 클래스
│   │   │   ├── controller/
│   │   │   │   └── NewsController.java         # REST 컨트롤러
│   │   │   ├── service/
│   │   │   │   └── CryptoPanicService.java     # CryptoPanic API 서비스
│   │   │   └── dto/
│   │   │       ├── CryptoNews.java             # 뉴스 DTO
│   │   │       └── CryptoPanicResponse.java    # API 응답 DTO
│   │   └── resources/
│   │       └── application.yml                 # 설정 파일
│   └── test/
│       └── java/com/prospero/               # 테스트 클래스
├── pom.xml                                     # Maven 설정
└── README.md                                   # 이 파일
```

## 의존성

- Spring Boot 3.2.0
- Spring Web
- Spring Data JPA
- Lombok
- H2 Database (개발/테스트)
- Jackson (JSON 처리)

## 설정

### CoinDesk API 키 설정

API 키는 `application.yml` 파일에 직접 설정되어 있습니다:

```yaml
coindesk:
  api:
    key: c8ab9e6fb8bb7a4bc1137dc540f784dc7915037f9078b02f5e7477bc5ddefcbc
```

API 키를 변경하려면 `src/main/resources/application.yml` 파일을 수정하세요.

## 개발 팁

### IDE 설정

IntelliJ IDEA에서:
1. File → Open → prospero_boot 폴더 선택
2. Maven 자동 설정 완료 후 시작

VS Code에서:
1. Extension: Extension Pack for Java 설치
2. F5로 디버깅 시작

### 로컬 테스트

```bash
# 최근 뉴스 30개 조회
curl "http://localhost:8080/api/news/latest?limit=30"

# 2026년 4월 29일 뉴스 조회
curl "http://localhost:8080/api/news/by-date?date=20260429"
```

## 라이센스

MIT
