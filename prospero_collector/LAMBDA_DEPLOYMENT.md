# Prospero_collector Lambda 배포 가이드

## 사전 준비

### 1. AWS 콘솔/CLI 준비
- AWS 계정 및 CLI 설정 (`aws configure`)
- 대상 리전: `ap-northeast-2` (서울) 권장

### 2. SSM Parameter Store에 FRED API 키 저장
Lambda에서 FRED API 키를 환경변수 대신 SSM으로 조회합니다.

```bash
aws ssm put-parameter \
  --name "/prospero/fred-api-key" \
  --value "YOUR_FRED_API_KEY" \
  --type "SecureString" \
  --region ap-northeast-2
```

---

## 배포 Pakage 만들기

### Step 1: 의존성 설치 (별도 폴더)
`boto3`는 Lambda 런타임에 포함되어 있으므로, `requests`만 포함합니다.

```bash
cd Prospero_collector
mkdir -p build
pip install requests -t build/ --upgrade
```

### Step 2: 코드 복사 및 zip 생성

```bash
# build 폴더에 소스 복사
cp lambda_function.py crypto_collector.py macro_collector.py dynamodb_writer.py build/

# zip 생성 (build 폴더 내용이 루트에 있어야 함)
cd build
zip -r ../prospero_collector.zip .
cd ..
```

### Step 3: 생성된 zip 확인
```bash
ls -la prospero_collector.zip
unzip -l prospero_collector.zip   # 내용 확인
```

---

## Lambda 함수 생성

### AWS CLI로 생성

```bash
aws lambda create-function \
  --function-name prospero-collector \
  --runtime python3.11 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://prospero_collector.zip \
  --role arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_LAMBDA_EXECUTION_ROLE \
  --timeout 60 \
  --memory-size 256 \
  --region ap-northeast-2
```

> **IAM Role**: `lambda_basic_execution` + DynamoDB PutItem + SSM GetParameter 권한 필요

### 기존 함수 업데이트

```bash
aws lambda update-function-code \
  --function-name prospero-collector \
  --zip-file fileb://prospero_collector.zip \
  --region ap-northeast-2
```

---

## 환경변수 설정

Lambda 콘솔 > Functions > prospero-collector > Configuration > Environment variables

| 키 | 값 | 필수 |
|----|-----|------|
| `DYNAMODB_CRYPTO_TABLE` | TB_CRYPTO_DATA | 선택 (기본값 사용 시 생략) |
| `DYNAMODB_MACRO_TABLE` | TB_MACRO_DATA | 선택 |
| `FRED_API_KEY_PARAM` | /prospero/fred-api-key | 선택 (다른 경로 사용 시) |

> `FRED_API_KEY`는 SSM에서 조회하므로 환경변수로 넣지 않아도 됩니다.  
> (환경변수에 넣으면 SSM보다 우선 사용됨)

---

## IAM 권한

Lambda 실행 Role에 다음 권한이 있어야 합니다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:ap-northeast-2:*:table/TB_CRYPTO_DATA",
        "arn:aws:dynamodb:ap-northeast-2:*:table/TB_MACRO_DATA"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter"
      ],
      "Resource": "arn:aws:ssm:ap-northeast-2:*:parameter/prospero/*"
    }
  ]
}
```

---

## EventBridge 스케줄 설정 (매일 UTC 04:00)

### Rule 생성
- **이름**: `prospero-collector-schedule`
- **스케줄**: `cron(0 4 * * ? *)` (매일 UTC 04:00)

### AWS CLI

```bash
# EventBridge Rule 생성
aws events put-rule \
  --name prospero-collector-schedule \
  --schedule-expression "cron(0 4 * * ? *)" \
  --state ENABLED \
  --region ap-northeast-2

# Lambda에 권한 부여 (EventBridge가 Lambda를 호출할 수 있도록)
aws lambda add-permission \
  --function-name prospero-collector \
  --statement-id prospero-collector-eventbridge \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:ap-northeast-2:YOUR_ACCOUNT_ID:rule/prospero-collector-schedule \
  --region ap-northeast-2

# Rule에 Lambda 타겟 연결
aws events put-targets \
  --rule prospero-collector-schedule \
  --targets "Id"="1","Arn"="arn:aws:lambda:ap-northeast-2:YOUR_ACCOUNT_ID:function:prospero-collector" \
  --region ap-northeast-2
```

> `YOUR_ACCOUNT_ID`를 실제 계정 ID로 바꾸세요.

---

## 배포 스크립트 (한 번에 실행)

`deploy.sh` 예시:

```bash
#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "=== Prospero_collector Lambda 배포 ==="

# 1. 빌드 폴더 정리
rm -rf build
mkdir -p build

# 2. 의존성 설치 (requests만)
pip install requests -t build/ --upgrade --quiet

# 3. 소스 복사
cp lambda_function.py crypto_collector.py macro_collector.py dynamodb_writer.py build/

# 4. zip 생성
cd build && zip -r ../prospero_collector.zip . && cd ..

# 5. Lambda 업데이트 (함수가 이미 있는 경우)
aws lambda update-function-code \
  --function-name prospero-collector \
  --zip-file fileb://prospero_collector.zip \
  --region ap-northeast-2

echo "=== 배포 완료 ==="
```

---

## 수동 테스트

### Lambda 콘솔에서 테스트
1. Lambda > prospero-collector > Test 탭
2. 테스트 이벤트 생성 (빈 객체 `{}` 또는 `{"date": "20260207"}`)
3. Test 실행

### CLI로 호출
```bash
aws lambda invoke \
  --function-name prospero-collector \
  --payload '{}' \
  --region ap-northeast-2 \
  response.json

cat response.json
```

---

## 트러블슈팅

| 증상 | 원인 | 해결 |
|------|------|------|
| `[WARN] FRED API 키가 없습니다` | SSM 조회 실패 | SSM Parameter `/prospero/fred-api-key` 생성 확인, IAM에 ssm:GetParameter 권한 |
| `DynamoDB 저장 실패` | 권한/테이블 없음 | IAM dynamodb:PutItem, 테이블명 확인 |
| `Task timed out` | API 응답 지연 | Lambda timeout 60초 이상으로 증가 |
| `Module not found: requests` | requests 미포함 | zip에 `requests` 패키지 포함 확인 |

---

## 체크리스트

- [ ] SSM Parameter `/prospero/fred-api-key` 생성
- [ ] Lambda 함수 생성 (또는 업데이트)
- [ ] IAM Role에 DynamoDB, SSM 권한 부여
- [ ] EventBridge Rule 생성 및 Lambda 타겟 연결
- [ ] 수동 테스트로 동작 확인
