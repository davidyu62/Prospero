# C4 범위 엔드포인트 배포 가이드

30일 추세 그래프에 실데이터를 공급하기 위한 신규 엔드포인트 배포 절차입니다.

- **신규 엔드포인트**: `GET /api/crypto-data/db/range?date=YYYYMMDD&days=30`
- **새 Lambda 함수 생성 없음** — 기존 함수 `prospero-retrieval`의 **코드만 갱신**하고, API Gateway에 **리소스 1개만 추가**합니다.
- 대상 API Gateway: `n84fir7sq6` (스테이지 `prod`), 리전 `ap-northeast-2`

> 앱은 이 엔드포인트 호출 실패 시 자동으로 예시(스텁) 데이터로 폴백하므로, 배포 전이라도 앱은 정상 동작합니다. 배포가 끝나면 실데이터로 자동 전환됩니다.

---

## 1단계. Lambda 코드 갱신 (터미널)

```bash
cd prospero_backend
./deploy.sh   # prospero_backend.zip 생성

aws lambda update-function-code \
  --function-name prospero-retrieval \
  --zip-file fileb://prospero_backend.zip \
  --region ap-northeast-2
```

이 단계만으로는 새 경로가 아직 API Gateway에 없어 외부에서 호출되지 않습니다(2단계 필요).
단, 기존 엔드포인트 동작에는 영향이 없습니다(순수 추가 변경).

## 2단계. API Gateway 리소스 추가 (콘솔 권장)

현재 IAM 사용자(davidyu)에 `apigateway` 권한이 없어 CLI로는 불가하므로 콘솔에서 진행합니다.

1. AWS 콘솔 → **API Gateway** → API `prospero`(ID `n84fir7sq6`) → **Resources**
2. 왼쪽 트리에서 **`/api/crypto-data/db`** 리소스 선택
3. **Create resource**
   - Resource name: `range`
   - Resource path: `range`
   - **Create**
4. 새로 만든 **`/range`** 리소스 선택 → **Create method** → **GET**
   - Integration type: **Lambda function**
   - **Lambda proxy integration**: **켬(ON)** ← 반드시 켤 것(쿼리스트링 전달)
   - Lambda function: `prospero-retrieval`
   - **Save** (권한 부여 팝업 뜨면 승인)
5. `/range` 리소스에서 **Enable CORS**
   - GET, OPTIONS 체크 → 저장 (앱은 Origin 무관하나 기존 방식과 통일)
6. **Deploy API** → Stage: **prod** → Deploy

## 3단계. 검증

```bash
curl "https://n84fir7sq6.execute-api.ap-northeast-2.amazonaws.com/prod/api/crypto-data/db/range?date=20260630&days=30"
```

- 정상: `{"dates":[...],"btcPrices":[...], ...}` 형태의 지표별 배열 JSON
- 앱을 다시 실행하면 크립토 카드의 스파크라인/상세 차트가 실제 30일 데이터로 그려지고, 상세 시트의 "예시 값" 문구가 사라집니다.

---

## 참고: 응답 형식

```json
{
  "dates": ["20260601", "20260602", ...],
  "btcPrices": [59000.1, 59250.4, ...],
  "longShortRatios": [1.9, 2.0, ...],
  "fearGreedIndices": [20, 18, ...],
  "openInterests": [98000.0, 99000.0, ...],
  "mvrvs": [1.9, 1.95, ...],
  "fundingRates": [-0.0001, 0.0002, ...],
  "activeAddresses": [780000, 790000, ...]
}
```

- 각 배열은 오래된 날짜 → 최신 날짜 순.
- `days`는 2~90 범위로 제한(기본 30). 데이터가 있는 날짜만 포함되므로 실제 길이는 30보다 짧을 수 있음.
- DynamoDB 조회는 하루 1건씩 최대 `days`회. boto3 클라이언트 1회 생성 + 파티션키(date) 단일 Query로 30일 ≈ 0.5초.

---

## 📌 매크로(Macro) range 추가 배포 (MacroTab M-C4)

크립토와 동일 구조로 **거시경제 범위 엔드포인트**가 추가되었습니다.
- **신규 엔드포인트**: `GET /api/macro-data/db/range?date=YYYYMMDD&days=30`
- 같은 Lambda `prospero-retrieval` 코드에 포함(위 1단계 zip 재업로드 시 함께 반영됨).

**1단계 (Lambda 코드)**: 위와 동일하게 `./deploy.sh` 후 `aws lambda update-function-code ...` 재실행하면 크립토·매크로 range가 **모두** 반영됩니다(순수 추가라 기존 동작 영향 없음).

**2단계 (API Gateway)**: 크립토와 똑같이 리소스를 하나 더 추가합니다.
1. API Gateway → `prospero`(`n84fir7sq6`) → Resources → **`/api/macro-data/db`** 선택
2. **Create resource** → name/path: `range` → Create
3. `/range` → **Create method GET** → Lambda **proxy 통합 ON** → `prospero-retrieval` → Save
4. **Enable CORS** → **Deploy API → prod**

**검증**:
```bash
curl "https://n84fir7sq6.execute-api.ap-northeast-2.amazonaws.com/prod/api/macro-data/db/range?date=20260630&days=30"
```
`{"dates":[...],"interestRates":[...],"cpis":[...], ...}` 형태면 성공. 앱 Macro 탭이 실제 30일 데이터로 그려집니다.
