# Prospero 앱 → API Gateway 마이그레이션 가이드

## 현재 구조

| 구성요소 | 현재 | 설명 |
|----------|------|------|
| **앱** | Prospero (SwiftUI) | `localhost:8080` 호출 |
| **백엔드** | AInvest_collector (Spring Boot) | DynamoDB 조회 API |
| **API 엔드포인트** | GET /api/crypto-data/db/date-with-previous?date={yyyyMMdd} | 크립토 |
| | GET /api/macro-data/db/date-with-previous?date={yyyyMMdd} | 매크로 |

---

## 목표 구조 (API Gateway)

```
Prospero 앱
    ↓ HTTPS
API Gateway (REST API)
    ↓
Lambda (prospero-api) → DynamoDB 조회
```

---

## 1단계: API용 Lambda 함수 생성

이미 생성된 파일:
- `dynamodb_reader.py` - DynamoDB Query
- `api_handler.py` - API Gateway Lambda Proxy 핸들러

### 1-1. prospero-api.zip 패키징

```bash
cd Prospero_collector
rm -rf build
mkdir -p build
cp api_handler.py dynamodb_reader.py build/

# boto3는 Lambda 런타임에 포함되므로 추가 불필요
cd build && zip -r ../prospero_api.zip . && cd ..
```

### 1-2. Lambda 함수 생성

```bash
# prospero-api Lambda 생성 (IAM Role은 prospero-collector와 동일한 DynamoDB 권한 사용)
aws lambda create-function \
  --function-name prospero-api \
  --runtime python3.11 \
  --handler api_handler.lambda_handler \
  --zip-file fileb://prospero_api.zip \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/prospero-collector-role-XXX \
  --timeout 10 \
  --memory-size 128 \
  --environment "Variables={DYNAMODB_CRYPTO_TABLE=TB_CRYPTO_DATA,DYNAMODB_MACRO_TABLE=TB_MACRO_DATA}" \
  --region ap-northeast-2
```

> 기존 `prospero-collector` Role에 `dynamodb:Query` 권한이 있어야 합니다. PutItem만 있으면 Query 추가 필요.

### 1-3. IAM 권한 (Query 추가)

```json
{
  "Effect": "Allow",
  "Action": ["dynamodb:Query", "dynamodb:GetItem"],
  "Resource": [
    "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
    "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
  ]
}
```

---

## 2단계: API Gateway REST API 생성

### 2-1. REST API 생성

```bash
aws apigateway create-rest-api --name prospero-api --region ap-northeast-2
# → apiId 저장
```

### 2-2. 리소스 ID 조회

```bash
API_ID="your-api-id"
ROOT_ID=$(aws apigateway get-resources --rest-api-id $API_ID --region ap-northeast-2 --query 'items[0].id' --output text)
```

### 2-3. 리소스 생성 (한 번에)

```bash
# /api
API_RES=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $ROOT_ID --path-part api --query 'id' --output text)

# /api/crypto-data
CRYPTO_RES=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $API_RES --path-part crypto-data --query 'id' --output text)

# /api/crypto-data/db
CRYPTO_DB=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $CRYPTO_RES --path-part db --query 'id' --output text)

# /api/crypto-data/db/date-with-previous
CRYPTO_DP=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $CRYPTO_DB --path-part date-with-previous --query 'id' --output text)

# /api/macro-data
MACRO_RES=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $API_RES --path-part macro-data --query 'id' --output text)

# /api/macro-data/db
MACRO_DB=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $MACRO_RES --path-part db --query 'id' --output text)

# /api/macro-data/db/date-with-previous
MACRO_DP=$(aws apigateway create-resource --rest-api-id $API_ID --parent-id $MACRO_DB --path-part date-with-previous --query 'id' --output text)
```

### 2-4. GET 메서드 + Lambda 통합 (crypto)

```bash
LAMBDA_ARN="arn:aws:lambda:ap-northeast-2:YOUR_ACCOUNT_ID:function:prospero-api"

aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CRYPTO_DP \
  --http-method GET \
  --authorization-type NONE \
  --region ap-northeast-2

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CRYPTO_DP \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:ap-northeast-2:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
  --region ap-northeast-2
```

### 2-5. GET 메서드 + Lambda 통합 (macro)

```bash
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $MACRO_DP \
  --http-method GET \
  --authorization-type NONE \
  --region ap-northeast-2

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $MACRO_DP \
  --http-method GET \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:ap-northeast-2:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
  --region ap-northeast-2
```

### 2-6. Lambda에 API Gateway 호출 권한 부여

```bash
aws lambda add-permission \
  --function-name prospero-api \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:ap-northeast-2:YOUR_ACCOUNT_ID:$API_ID/*" \
  --region ap-northeast-2
```

### 2-7. 배포

```bash
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod \
  --region ap-northeast-2
```

### 2-8. 최종 URL

```
https://<API_ID>.execute-api.ap-northeast-2.amazonaws.com/prod
```

- 크립토: `https://<API_ID>.execute-api.ap-northeast-2.amazonaws.com/prod/api/crypto-data/db/date-with-previous?date=20260207`
- 매크로: `https://<API_ID>.execute-api.ap-northeast-2.amazonaws.com/prod/api/macro-data/db/date-with-previous?date=20260207`

---

## 3단계: Prospero 앱 변경

### 3-1. baseURL 수정

**CryptoAPIService.swift**, **MacroAPIService.swift**:

```swift
#if DEBUG
private let baseURL = "http://localhost:8080"
#else
private let baseURL = "https://YOUR_API_ID.execute-api.ap-northeast-2.amazonaws.com/prod"
#endif
```

### 3-2. API 경로 (변경 없음)

- `/api/crypto-data/db/date-with-previous?date=`
- `/api/macro-data/db/date-with-previous?date=`

---

## 4단계: 로컬 테스트

```bash
# api_handler 로컬 테스트
cd Prospero_collector
python3 -c "
from api_handler import lambda_handler
event = {'httpMethod':'GET','path':'/api/crypto-data/db/date-with-previous','queryStringParameters':{'date':'20260207'}}
print(lambda_handler(event, None))
"
```

---

## 요약 체크리스트

- [x] `dynamodb_reader.py` 작성
- [x] `api_handler.py` 작성
- [ ] Lambda `prospero-api` 생성 및 배포
- [ ] IAM에 dynamodb:Query 권한 추가
- [ ] API Gateway REST API 생성
- [ ] 리소스/메서드 생성 및 Lambda 연결
- [ ] 배포 후 Invoke URL 확인
- [ ] Prospero 앱 baseURL 변경
- [ ] 테스트

---

## 비용 (예상)

| 항목 | 월 1만 요청 | 월 10만 요청 |
|------|-------------|--------------|
| API Gateway | ~$0.04 | ~$0.35 |
| Lambda | ~$0.20 | ~$2.00 |
| **합계** | **~$0.25** | **~$2.35** |
