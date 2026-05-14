# CLAUDE.md

이 파일은 Claude Code(claude.ai/code)가 이 저장소에서 작업할 때 참고하는 지침을 제공합니다.

## 언어 지침

**모든 문서, 주석, 코드**: 한글
**Git 커밋 메시지**: 영어

## 프로젝트 개요

**Prospero**는 암호화폐/거시경제 데이터 기반 투자 인사이트 서비스.

- `prospero_boot` (Spring Boot): Spring MVC 백엔드
- `prospero_collector` (Python): 외부 API에서 암호화폐/거시경제 데이터 수집 (Lambda)
- `prospero_app` (iOS SwiftUI): 투자 분석 데이터 표시 앱
- `prospero_backend` (Python): REST API 백엔드 (Lambda)

상세: [docs/architecture.md](docs/architecture.md)

## 빌드 및 테스트 명령어

### prospero_boot (Spring Boot)

```bash
cd prospero_boot
mvn test          # 테스트 실행
mvn clean package # 빌드
```

### prospero_collector (Python Lambda)

```bash
cd prospero_collector
python run_local.py 20250114  # 로컬 테스트 (AWS 자격증명 필요)
```

### prospero_backend (Python Lambda)

```bash
cd prospero_backend
# 로컬 테스트는 dynamodb_reader.py 직접 테스트
```

### prospero_app (iOS)

```bash
open prospero_app/Prospero.xcodeproj  # Xcode로 열기
xcodebuild -project prospero_app/Prospero.xcodeproj \
  -scheme Prospero -sdk iphonesimulator -configuration Debug
```

## Claude 주의사항

(사용자가 발견한 실수 항목 추가)

## 참조 문서

- [docs/architecture.md](docs/architecture.md) - 아키텍처, AWS 설정, 파일 구조
- [HARNESS_ENGINEERING.md](HARNESS_ENGINEERING.md) - 통합 테스트 및 CI/CD 가이드
