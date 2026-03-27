# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 지침을 제공합니다.

## 언어 지침

**이 프로젝트의 모든 문서, 주석, 커밋 메시지는 한글로 작성합니다.**
- README, 배포 가이드, 설정 파일 주석: 한글
- 코드 내 주석: 한글
- Git 커밋 메시지: 영어
- 새로운 문서 작성: 한글

## 프로젝트 개요

**Prospero**는 암호화폐/거시경제 데이터 기반 투자 인사이트 서비스로 세 가지 주요 컴포넌트로 구성됩니다:
- iOS SwiftUI 앱: 투자 분석 데이터 표시
- 데이터 수집기: 외부 API에서 암호화폐 및 거시경제 데이터 수집
- REST API 백엔드: 앱에 데이터 제공

## 아키텍처

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

## 빌드, 테스트, 배포 명령어

### prospero_app (iOS)

```bash
# Xcode에서 프로젝트 열기
open prospero_app/Prospero.xcodeproj

# 시뮬레이터 빌드 (명령줄)
xcodebuild -project prospero_app/Prospero.xcodeproj -scheme Prospero -sdk iphonesimulator -configuration Debug

# 연결된 기기 목록 확인
xcrun xctrace list devices
```

실제 기기에 빌드할 때는 Xcode의 Signing & Capabilities에서 Apple ID로 서명 설정. 자세한 설정은 `prospero_app/README.md` 참조.

### prospero_collector (Python Lambda)

```bash
cd prospero_collector

# 로컬 테스트 (AWS 자격증명 및 FRED API 키 필요)
export FRED_API_KEY=your_key
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_DEFAULT_REGION=ap-northeast-2
python run_local.py              # 오늘 날짜로 테스트
python run_local.py 20250101     # 특정 날짜로 테스트

# Lambda에 배포
./deploy.sh
# 또는 함수명 지정:
./deploy.sh 함수명
```

필요한 환경변수:
- `FRED_API_KEY`: FRED API 키 (또는 Lambda의 SSM Parameter Store 사용)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`: AWS 자격증명
- `AWS_DEFAULT_REGION`: ap-northeast-2 (서울)
- `DYNAMODB_CRYPTO_TABLE`: TB_CRYPTO_DATA
- `DYNAMODB_MACRO_TABLE`: TB_MACRO_DATA

### prospero_backend (Python Lambda + API Gateway)

```bash
cd prospero_backend

# 로컬 테스트 (AWS 자격증명 및 DynamoDB 접근 필요)
python3 -c "
from api_handler import lambda_handler
event = {
    'httpMethod': 'GET',
    'path': '/api/crypto-data/db/date-with-previous',
    'queryStringParameters': {'date': '20250207'}
}
result = lambda_handler(event, None)
print(result)
"

# Lambda에 배포
./deploy.sh
# 또는 함수명 지정:
./deploy.sh 함수명
```

## 핵심 파일 및 구조

**prospero_collector/**
- `lambda_function.py` - Lambda 진입점 (수집 오케스트레이션)
- `crypto_collector.py` - Binance, Alternative.me 데이터 수집
- `macro_collector.py` - FRED API 데이터 수집
- `dynamodb_writer.py` - DynamoDB 테이블 쓰기
- `run_local.py` - 로컬 테스트 실행기
- `deploy.sh` - Lambda 배포 스크립트
- `LAMBDA_DEPLOYMENT.md` - Lambda 설정 상세 가이드

**prospero_backend/**
- `api_handler.py` - API Gateway 프록시용 Lambda 핸들러
- `dynamodb_reader.py` - DynamoDB 조회 로직
- `deploy.sh` - Lambda 배포 스크립트
- `DEPLOYMENT.md` - API Gateway 및 Lambda 설정 상세 가이드

**prospero_app/**
- `Prospero/` - SwiftUI 소스 코드
- `Prospero.xcodeproj/` - Xcode 프로젝트
- `APP_ICON_GENERATOR.md` - 앱 아이콘 생성 가이드
- `SIMULATOR_GUIDE.md` - iOS 시뮬레이터 설정
- `endpoint.md` - API 엔드포인트 설정

## AWS 설정

**리전**: `ap-northeast-2` (서울)

**DynamoDB 테이블** (prospero_collector가 생성):
- `TB_CRYPTO_DATA` - 암호화폐 시장 데이터, crypto_id/date 파티션 키
- `TB_MACRO_DATA` - 거시경제 데이터, indicator_id/date 파티션 키

**Lambda 함수**:
- `prospero-collector` - 데이터 수집 (EventBridge 스케줄: `cron(0 4 * * ? *)` 매일 UTC 04:00)
- `prospero-retrieval` (또는 커스텀명) - API 백엔드

**필요한 IAM 권한**:
- prospero_collector: `dynamodb:PutItem`, `ssm:GetParameter` (FRED API 키용)
- prospero_retrieval: `dynamodb:Query`, `dynamodb:GetItem`

**API Gateway**:
- prospero-retrieval Lambda로 프록시 통합된 REST API
- 두 개의 리소스: `/api/crypto-data/db/date-with-previous`, `/api/macro-data/db/date-with-previous`

## 개발 노트

- prospero_collector, prospero_backend의 `.env` 파일로 로컬에서 AWS 자격증명 및 설정 로드 가능
- prospero_app은 iOS 16.2 이상 필요 (Xcode 프로젝트 설정에서 확인)
- 모든 Python 코드는 Python 3.11 사용 (Lambda 런타임)
- boto3는 Lambda 런타임에 포함, prospero_collector에는 requests 라이브러리만 배포 필요
- iOS 앱의 URL 엔드포인트는 `http://localhost:8080` (DEBUG)과 프로덕션 API Gateway URL (RELEASE)로 전환 (CryptoAPIService.swift, MacroAPIService.swift 참조)
