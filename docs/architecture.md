# Prospero 아키텍처 및 AWS 설정

## 아키텍처 다이어그램

```
prospero_collector (Python Lambda)
  ├── 암호화폐 데이터 수집: Binance API, Alternative.me (공포&탐욕)
  ├── 거시경제 데이터 수집: FRED API (경제 지표)
  └── DynamoDB 저장: TB_CRYPTO_DATA, TB_MACRO_DATA
       (매일 UTC 04:00에 EventBridge로 자동 실행)

prospero_backend (Python Lambda + API Gateway)
  ├── /api/crypto-data/db/date-with-previous?date={yyyyMMdd}
  ├── /api/macro-data/db/date-with-previous?date={yyyyMMdd}
  └── DynamoDB에서 암호화폐/거시경제 데이터 조회

prospero_app (iOS SwiftUI)
  ├── prospero_backend REST API 호출
  └── 암호화폐/거시경제 대시보드 표시
```

## 컴포넌트별 파일 구조

### prospero_collector/

- `lambda_function.py` - Lambda 진입점 (수집 오케스트레이션)
- `crypto_collector.py` - Binance, Alternative.me 데이터 수집
- `macro_collector.py` - FRED API 데이터 수집
- `dynamodb_writer.py` - DynamoDB 테이블 쓰기
- `run_local.py` - 로컬 테스트 실행기
- `LAMBDA_DEPLOYMENT.md` - Lambda 설정 상세 가이드

### prospero_backend/

- `api_handler.py` - API Gateway 프록시용 Lambda 핸들러
- `dynamodb_reader.py` - DynamoDB 조회 로직
- `DEPLOYMENT.md` - API Gateway 및 Lambda 설정 상세 가이드

### prospero_app/

- `Prospero/` - SwiftUI 소스 코드
- `Prospero.xcodeproj/` - Xcode 프로젝트
- `README.md` - 앱 개발 가이드
- `endpoint.md` - API 엔드포인트 설정

### prospero_boot/ (Spring Boot)

- `pom.xml` - Maven 빌드 설정
- `src/main/java/com/prospero/` - 애플리케이션 소스
- `src/test/java/com/prospero/` - JUnit 테스트

## AWS 설정

### 리전
`ap-northeast-2` (서울)

### DynamoDB 테이블

| 테이블명 | 용도 | 파티션 키 |
|---|---|---|
| `TB_CRYPTO_DATA` | 암호화폐 시장 데이터 | `crypto_id` / `date` |
| `TB_MACRO_DATA` | 거시경제 데이터 | `indicator_id` / `date` |

### Lambda 함수

| 함수명 | 역할 | 트리거 |
|---|---|---|
| `prospero-collector` | 데이터 수집 | EventBridge (cron: `0 4 * * ? *` UTC 매일 04:00) |
| `prospero-retrieval` | API 백엔드 | API Gateway 프록시 |

### IAM 권한

**prospero_collector**:
- `dynamodb:PutItem` - TB_CRYPTO_DATA, TB_MACRO_DATA 쓰기
- `ssm:GetParameter` - FRED API 키 조회 (Parameter Store)

**prospero_retrieval**:
- `dynamodb:Query` - DynamoDB 조회
- `dynamodb:GetItem` - 단일 항목 조회

### API Gateway

- REST API: `prospero-retrieval` Lambda로 프록시 통합
- 리소스:
  - `/api/crypto-data/db/date-with-previous` (GET)
  - `/api/macro-data/db/date-with-previous` (GET)

## 개발 노트

- **Python 버전**: 3.11 (Lambda 런타임)
- **boto3**: Lambda 런타임에 포함, 별도 배포 불필요
- **prospero_collector 배포**: `requests` 라이브러리만 필요
- **iOS 최소 버전**: iOS 16.2 이상
- **환경 변수**: `.env` 파일로 로컬에서 AWS 자격증명 로드 가능
  - `FRED_API_KEY` - FRED API 키
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` - AWS 자격증명
  - `AWS_DEFAULT_REGION` - ap-northeast-2
  - `DYNAMODB_CRYPTO_TABLE` - TB_CRYPTO_DATA
  - `DYNAMODB_MACRO_TABLE` - TB_MACRO_DATA
- **앱 엔드포인트 전환**:
  - DEBUG 빌드: `http://localhost:8080` (로컬 백엔드)
  - RELEASE 빌드: AWS API Gateway URL (프로덕션)
  - 파일: `CryptoAPIService.swift`, `MacroAPIService.swift` 참조

## 참고 문서

- CLAUDE.md - Claude Code 지침 및 핵심 명령어
- HARNESS_ENGINEERING.md - 통합 테스트 및 CI/CD 구성 가이드
- prospero_collector/LAMBDA_DEPLOYMENT.md
- prospero_backend/DEPLOYMENT.md
- prospero_app/README.md
