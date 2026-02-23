# prospero_app 외부 엔드포인트 문서

## 개요
prospero_app (iOS Swift 앱)이 호출하는 외부 엔드포인트 정리 문서입니다.
백엔드 개발 및 운영 시 참고하시기 바랍니다.

### 공통 설정
- **Base URL**: `https://yjyjxewr8c.execute-api.ap-northeast-2.amazonaws.com/prod`
- **인증**: 헤더 없음
- **프로토콜**: HTTPS
- **요청 방식**: `URLSession.shared.data(from: url)` (GET)

---

## REST API 엔드포인트

### 1. 암호화폐 데이터 조회 (전날 데이터 포함)
| 항목 | 값 |
|------|-----|
| **Method** | GET |
| **Path** | `/api/crypto-data/db/date-with-previous` |
| **Query Parameter** | `date=yyyyMMdd` (예: `date=20260223`) |
| **Response Type** | `CryptoAPIResponse` |
| **호출 파일** | `Services/CryptoAPIService.swift:18` |
| **함수명** | `fetchCryptoDataWithPrevious(date:)` |

**Example Request**:
```
GET https://yjyjxewr8c.execute-api.ap-northeast-2.amazonaws.com/prod/api/crypto-data/db/date-with-previous?date=20260223
```

**Response Structure**:
- Type: `CryptoAPIResponse` (Swift Codable)
- 정의 파일: `Models/CryptoAPIResponse.swift`
- HTTP Status: 200 (Success)

---

### 2. 거시경제 데이터 조회 (전날 데이터 포함)
| 항목 | 값 |
|------|-----|
| **Method** | GET |
| **Path** | `/api/macro-data/db/date-with-previous` |
| **Query Parameter** | `date=yyyyMMdd` (예: `date=20260223`) |
| **Response Type** | `MacroAPIResponse` |
| **호출 파일** | `Services/MacroAPIService.swift:18` |
| **함수명** | `fetchMacroDataWithPrevious(date:)` |

**Example Request**:
```
GET https://yjyjxewr8c.execute-api.ap-northeast-2.amazonaws.com/prod/api/macro-data/db/date-with-previous?date=20260223
```

**Response Structure**:
- Type: `MacroAPIResponse` (Swift Codable)
- 정의 파일: `Models/MacroAPIResponse.swift`
- HTTP Status: 200 (Success)

---

## AdMob SDK 통합

### 3. 배너 광고
| 항목 | 값 |
|------|-----|
| **종류** | Google AdMob Banner Ad |
| **Ad Unit ID** | `ca-app-pub-3940256099942544/2435281174` |
| **상태** | **테스트 ID** (배포 전 교체 필수) |
| **호출 파일** | `Views/Components/BannerAdView.swift:26` |
| **View 타입** | SwiftUI UIViewRepresentable |

**사용 위치**:
- ContentView 및 Dashboard Views에 배치
- 높이: 50pt
- Adaptive Banner (화면 너비에 맞춤)

---

### 4. 리워드 광고
| 항목 | 값 |
|------|-----|
| **종류** | Google AdMob Rewarded Ad |
| **Ad Unit ID** | `ca-app-pub-3940256099942544/1712485313` |
| **상태** | **테스트 ID** (배포 전 교체 필수) |
| **호출 파일** | `Services/RewardedAdManager.swift:18` |
| **Manager 타입** | Singleton (@MainActor) |

**사용 방식**:
- AI 탭 진입 시 광고 표시
- 광고 시청 완료 후에만 AI 페이지 진입 가능
- `loadAd()`: 광고 미리 로드 (앱 시작 시 권장)
- `showAd(onReward:onAdNotReady:)`: 광고 표시 및 콜백 처리

---

## 주의사항

✅ **AWS API Gateway 연동 완료**
- Base URL이 AWS API Gateway로 설정됨: `https://yjyjxewr8c.execute-api.ap-northeast-2.amazonaws.com/prod`
- HTTPS 프로토콜 사용으로 ATS (App Transport Security) 자동 준수
- Stage 이름이 변경되면 Base URL의 `/prod` 부분 수정 필요
- 변경 위치: `CryptoAPIService.swift:13`, `MacroAPIService.swift:13`

⚠️ **테스트 광고 ID**
- AdMob Banner ID와 Rewarded ID는 모두 Google 테스트 ID
- 실제 배포 시 본인의 Ad Unit ID로 교체 필수
- 변경 위치:
  - `BannerAdView.swift:26`
  - `RewardedAdManager.swift:18`

⚠️ **인증 없음**
- REST API 엔드포인트에 인증 헤더 미포함
- 필요 시 인증 로직 추가 필요

---

## 에러 처리

### REST API 에러 처리
- `APIError.invalidURL`: URL 형식 오류
- `APIError.invalidResponse`: HTTP 상태 코드 != 200
- `APIError.decodingError`: JSON 디코딩 실패

응답 로깅:
- 성공 시: HTTP 상태 코드, 응답 데이터 크기 로깅
- 실패 시: 상태 코드, 응답 본문, 디코딩 에러 상세 로깅

### AdMob 에러 처리
- 배너: `bannerView(_:didFailToReceiveAdWithError:)` delegate 호출
- 리워드: 로드 실패 시 `onAdNotReady` 콜백 호출

---

## 참고 자료

| 파일 | 용도 |
|------|------|
| `Services/CryptoAPIService.swift` | 암호화폐 데이터 API 호출 |
| `Services/MacroAPIService.swift` | 거시경제 데이터 API 호출 |
| `Services/RewardedAdManager.swift` | 리워드 광고 관리 |
| `Views/Components/BannerAdView.swift` | 배너 광고 UI |
| `Models/CryptoAPIResponse.swift` | 암호화폐 API 응답 구조 |
| `Models/MacroAPIResponse.swift` | 거시경제 API 응답 구조 |

---

**마지막 업데이트**: 2026-02-23
