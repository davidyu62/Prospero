# Lambda 데이터 수집기 이전 계획

## 현재 아키텍처 요약

- **스케줄러**: DataCollectorScheduler (Spring @Scheduled, 매일 04:00 KST)
- **배치**: BatchService → CryptoService + MacroService → DynamoDBService
- **저장**: TB_CRYPTO_DATA, TB_MACRO_DATA

**외부 API:**
- **크립토**: Binance (공개 API), Alternative.me (Fear & Greed) - 인증 불필요
- **매크로**: FRED API - `fred.api.key` 필요

---

## 목표 아키텍처

- **EventBridge Rule**: cron(0 4 * * ? *) → 매일 UTC 04:00
- **Lambda**: 크립토/매크로 조회 → DynamoDB PutItem
- **SSM Parameter Store**: FRED API 키 저장

---

## 구현 단계

1. Lambda 프로젝트 구조 생성
2. crypto_collector.py - Binance, Alternative.me HTTP 호출
3. macro_collector.py - FRED API 호출 (6개 시리즈)
4. dynamodb_writer.py - PutItem (date, timestamps 키)
5. lambda_function.py - 핸들러 + 수집/저장 로직
6. requirements.txt - requests, boto3

---

## IAM 권한

- dynamodb:PutItem (TB_CRYPTO_DATA, TB_MACRO_DATA)
- ssm:GetParameter (FRED API 키)
- logs:CreateLogGroup, logs:CreateLogStream, logs:PutLogEvents

---

## 주의사항

1. 동일 DynamoDB 테이블 사용 (TB_CRYPTO_DATA, TB_MACRO_DATA)
2. EventBridge는 UTC 기준 (매일 04:00 UTC 실행)
3. Lambda 타임아웃 60초 이상 권장
