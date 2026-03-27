# Prospero AI Lambda 배포 가이드

## 1. DynamoDB 테이블 생성

### TB_AI_INSIGHT 테이블 (신규 생성)

**목적**: 매일 계산된 비트코인 투자 점수 및 분석 결과 저장

**테이블 설정**:
```
테이블명: TB_AI_INSIGHT
파티션 키: date (String)
```

**AWS CLI로 생성**:
```bash
aws dynamodb create-table \
  --table-name TB_AI_INSIGHT \
  --attribute-definitions AttributeName=date,AttributeType=S \
  --key-schema AttributeName=date,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-northeast-2
```

**속성 (자동 저장, 스키마 정의 불필요)**:
| 속성명 | 타입 | 설명 |
|-------|------|------|
| `date` | String | 파티션 키 (yyyyMMdd) |
| `total_score` | Number | 0-100 총점 |
| `signal_type` | String | Strong Buy / Buy / Hold / Partial Sell / Strong Sell |
| `signal_color` | String | strong_buy / buy / hold / partial_sell / strong_sell |
| `crypto_score` | Number | 크립토 지표 소계 (0-60) |
| `macro_score` | Number | 매크로 지표 소계 (0-40) |
| `fear_greed_score` | Number | 공포탐욕지수 점수 |
| `long_short_score` | Number | 롱숏비율 점수 |
| `exchange_balance_score` | Number | 거래소잔고 점수 |
| `open_interest_score` | Number | OI+가격 점수 |
| `interest_rate_score` | Number | 기준금리 점수 |
| `m2_score` | Number | M2 점수 |
| `dollar_index_score` | Number | 달러인덱스 점수 |
| `cpi_score` | Number | CPI 점수 |
| `analysis_summary` | String | LLM 생성 종합 요약 |
| `indicator_explanations` | String | JSON 문자열 - 지표별 설명 |
| `created_at` | String | ISO 타임스탬프 |

---

## 2. IAM 역할 및 권한 설정

### Lambda 실행 역할 생성

```bash
# 1. 신뢰 정책 파일 생성 (trust-policy.json)
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# 2. 역할 생성
aws iam create-role \
  --role-name prospero-ai-lambda-role \
  --assume-role-policy-document file://trust-policy.json

# 3. 권한 정책 파일 생성 (policy.json)
cat > policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:BatchGetItem",
        "dynamodb:Query"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
        "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": "arn:aws:dynamodb:ap-northeast-2:*:table/TB_AI_INSIGHT"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:ap-northeast-2:*:*"
    }
  ]
}
EOF

# 4. 권한 정책 연결
aws iam put-role-policy \
  --role-name prospero-ai-lambda-role \
  --policy-name prospero-ai-policy \
  --policy-document file://policy.json
```

역할 ARN 확인:
```bash
aws iam get-role --role-name prospero-ai-lambda-role --query 'Role.Arn' --output text
# 출력: arn:aws:iam::123456789012:role/prospero-ai-lambda-role
```

---

## 3. Lambda 함수 배포

### 로컬에서 테스트

```bash
cd prospero_ai

# .env 파일 생성
cat > .env << 'EOF'
OPENAI_API_KEY=sk-...
DYNAMODB_CRYPTO_TABLE=TB_CRYPTO_DATA
DYNAMODB_MACRO_TABLE=TB_MACRO_DATA
DYNAMODB_AI_TABLE=TB_AI_INSIGHT
AWS_DEFAULT_REGION=ap-northeast-2
EOF

# 로컬 테스트 실행
export OPENAI_API_KEY=sk-...
python run_local.py 20250304
```

### Lambda 함수 등록 및 배포

```bash
# 1. deploy.sh 스크립트 실행 (자동으로 함수 생성 또는 업데이트)
cd prospero_ai
chmod +x deploy.sh
./deploy.sh prospero-ai

# 2. 환경 변수 설정 (OpenAI API 키)
aws lambda update-function-configuration \
  --function-name prospero-ai \
  --region ap-northeast-2 \
  --environment Variables="{OPENAI_API_KEY=sk-...,DYNAMODB_CRYPTO_TABLE=TB_CRYPTO_DATA,DYNAMODB_MACRO_TABLE=TB_MACRO_DATA,DYNAMODB_AI_TABLE=TB_AI_INSIGHT,AWS_DEFAULT_REGION=ap-northeast-2}"

# 3. 함수 설정 확인
aws lambda get-function-configuration \
  --function-name prospero-ai \
  --region ap-northeast-2
```

### Lambda 함수 속성

| 속성 | 값 |
|------|-----|
| 함수명 | `prospero-ai` |
| 런타임 | Python 3.11 |
| 핸들러 | `lambda_function.lambda_handler` |
| 타임아웃 | 60초 |
| 메모리 | 256MB |
| 역할 | `arn:aws:iam::...:role/prospero-ai-lambda-role` |

### Mac에서 배포 시: `pydantic_core` / `langchain_core` ImportError

Mac에서 `pip install`로 패키지를 넣으면 **pydantic**, **langchain**의 네이티브 확장이 Mac용으로 빌드되어, Lambda(Amazon Linux x86_64)에서 `No module named 'pydantic_core._pydantic_core'` 같은 오류가 납니다.

**조치**: `deploy.sh`가 이미 **Lambda와 동일한 플랫폼**으로 의존성을 받도록 수정돼 있습니다.  
`pip3 install` 시 `--platform manylinux2014_x86_64 --python-version 3.11`을 사용해 Linux x86_64용 휠을 받습니다.  
**`./deploy.sh`를 다시 실행**해 새 zip으로 Lambda를 업데이트하면 됩니다.

그래도 동일 오류가 나면, Lambda와 같은 환경에서 빌드해야 합니다. Docker 예시:

```bash
docker run --rm -v "$(pwd):/out" public.ecr.aws/sam/build-python3.11:latest \
  pip install -r requirements.txt -t /out/build/
# 이후 build/ 에 소스 복사 후 zip 생성
```

---

## 4. EventBridge 스케줄러 설정

매일 UTC 05:00에 Lambda 실행하도록 설정 (데이터 수집기 1시간 후)

### EventBridge 규칙 생성

```bash
# 1. 규칙 생성
aws events put-rule \
  --name prospero-ai-daily \
  --schedule-expression 'cron(0 5 * * ? *)' \
  --state ENABLED \
  --region ap-northeast-2

# 2. Lambda를 규칙의 대상으로 등록
aws events put-targets \
  --rule prospero-ai-daily \
  --targets "Id"="1","Arn"="arn:aws:lambda:ap-northeast-2:123456789012:function:prospero-ai","RoleArn"="arn:aws:iam::123456789012:role/service-role/EventBridgeInvokeRole" \
  --region ap-northeast-2

# 3. Lambda 함수에 EventBridge 호출 권한 부여
aws lambda add-permission \
  --function-name prospero-ai \
  --statement-id AllowEventBridgeInvoke \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:ap-northeast-2:123456789012:rule/prospero-ai-daily \
  --region ap-northeast-2
```

### 규칙 확인

```bash
# 규칙 상세 조회
aws events describe-rule --name prospero-ai-daily --region ap-northeast-2

# 규칙의 대상 확인
aws events list-targets-by-rule --rule prospero-ai-daily --region ap-northeast-2
```

---

## 5. Lambda 테스트

### 수동 테스트 (콘솔)

```bash
# Lambda 함수 직접 호출
aws lambda invoke \
  --function-name prospero-ai \
  --region ap-northeast-2 \
  --payload '{}' \
  response.json

# 응답 확인
cat response.json
```

### CloudWatch 로그 확인

```bash
# 최근 로그 출력
aws logs tail /aws/lambda/prospero-ai --follow --region ap-northeast-2
```

---

## 6. prospero_backend 업데이트 (API 엔드포인트 추가)

현재 prospero_backend의 `api_handler.py`에 다음 엔드포인트를 추가해야 합니다:

```python
# GET /api/ai-analysis/date?date={yyyyMMdd}
# 응답: {
#   "date": "20250304",
#   "total_score": 72.5,
#   "signal_type": "Buy",
#   ...
# }
```

자세한 내용은 `prospero_backend/DEPLOYMENT.md` 참조

---

## 7. 체크리스트

- [ ] TB_AI_INSIGHT 테이블 생성
- [ ] IAM 역할 및 권한 설정
- [ ] OPENAI_API_KEY 발급 (https://platform.openai.com/api-keys)
- [ ] prospero_ai 로컬 테스트 완료
- [ ] Lambda 함수 배포 (`./deploy.sh`)
- [ ] Lambda 환경 변수 설정 (OpenAI API 키)
- [ ] EventBridge 규칙 생성
- [ ] Lambda EventBridge 호출 권한 부여
- [ ] prospero_backend API 엔드포인트 추가
- [ ] prospero_backend Lambda 재배포
- [ ] iOS 앱 배포 (새 API 엔드포인트 사용)

---

## 8. 문제 해결

### Lambda 함수 시간 초과
- 타임아웃 60초에서 120초로 증가
- OpenAI API 응답 지연 확인

### DynamoDB 용량 부족
- PAY_PER_REQUEST 가격 정책 사용하므로 자동 스케일링됨
- CloudWatch 메트릭 확인

### OpenAI API 에러
- API 키 확인
- 요청 레이트 제한 (100 RPM, 3.5M tokens/min) 확인
- 모델 이용 가능 상태 확인
