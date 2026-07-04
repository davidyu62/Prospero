# Prospero Harness 엔지니어링 가이드

이 문서는 Prospero 프로젝트의 세 가지 컴포넌트(iOS 앱, 데이터 수집기, REST API 백엔드)를 통합하여 테스트하는 harness 엔지니어링 절차 및 방법을 정의합니다.

## 1. Harness 엔지니어링 개요

### 목표
- **통합 테스트 자동화**: 세 컴포넌트 간 상호작용을 자동으로 검증
- **엔드-투-엔드 시나리오 테스트**: 데이터 수집 → 저장 → 조회 → 앱 표시의 전체 flow 검증
- **배포 안정성 보증**: 각 컴포넌트 배포 후 통합 검증
- **로컬/스테이징/프로덕션 환경 모두 지원**

### 주요 구성요소
1. **로컬 테스트 하네스** - 개발 환경에서 신속한 검증
2. **Docker 기반 테스트 환경** - 격리된 환경에서 재현 가능한 테스트
3. **AWS 통합 테스트** - 실제 AWS 환경에서의 검증
4. **CI/CD 파이프라인** - 자동화된 배포 및 검증

---

## 2. 아키텍처 및 테스트 전략

### 2.1 컴포넌트별 테스트 계층

```
┌─────────────────────────────────────────────────────┐
│  iOS App (SwiftUI)                                  │
│  - 단위 테스트: View Model, Service 로직            │
│  - UI 테스트: Navigation, Data Display              │
│  - 통합 테스트: API 호출 시뮬레이션                 │
└─────────────────┬───────────────────────────────────┘
                  │ REST API 호출
┌─────────────────▼───────────────────────────────────┐
│  prospero_backend (Python Lambda)                   │
│  - 단위 테스트: DynamoDB 조회 로직                  │
│  - 통합 테스트: API Gateway 프록시                  │
│  - E2E 테스트: 앱과의 요청/응답 검증               │
└─────────────────┬───────────────────────────────────┘
                  │ DynamoDB 쿼리
┌─────────────────▼───────────────────────────────────┐
│  DynamoDB (AWS 또는 Local)                         │
│  - 데이터 상태 검증                                 │
└─────────────────────────────────────────────────────┘
```

### 2.2 테스트 피라미드 구조

```
        /\                    E2E 테스트
       /  \                   (앱 + 백엔드 + DB)
      /    \
     /──────\                 통합 테스트
    /        \                (백엔드 + DB)
   /          \
  /────────────\              단위 테스트
 /              \             (함수/메서드 수준)
/________________\
```

---

## 3. 로컬 개발 환경 Harness

### 3.1 로컬 스택 구성

```bash
# 1. DynamoDB Local (Docker)
docker run -d -p 8000:8000 amazon/dynamodb-local

# 2. prospero_backend 로컬 실행
cd prospero_backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python3 run_local.py

# 3. prospero_app 시뮬레이터 빌드
cd prospero_app
open Prospero.xcodeproj
# Xcode에서 시뮬레이터 선택 후 Build & Run
```

### 3.2 로컬 테스트 하네스 실행

#### 3.2.1 prospero_collector 로컬 테스트
```bash
cd prospero_collector

# 환경 설정
export FRED_API_KEY=your_fred_key
export AWS_ACCESS_KEY_ID=local
export AWS_SECRET_ACCESS_KEY=local
export AWS_DEFAULT_REGION=ap-northeast-2
export DYNAMODB_ENDPOINT_URL=http://localhost:8000  # Local DynamoDB

# 테스트 실행
python run_local.py 20250101  # 특정 날짜로 테스트

# 결과 검증
python3 -c "
import boto3
dynamodb = boto3.resource('dynamodb', endpoint_url='http://localhost:8000', region_name='ap-northeast-2')
table = dynamodb.Table('TB_CRYPTO_DATA')
response = table.get_item(Key={'crypto_id': 'BTC', 'date': '20250101'})
print(response.get('Item', 'No data'))
"
```

#### 3.2.2 prospero_backend 로컬 테스트
```bash
cd prospero_backend

# 환경 설정 (.env 파일 생성)
cat > .env << 'EOF'
AWS_DEFAULT_REGION=ap-northeast-2
DYNAMODB_ENDPOINT_URL=http://localhost:8000
AWS_ACCESS_KEY_ID=local
AWS_SECRET_ACCESS_KEY=local
EOF

# 로컬 테스트 서버 실행
python3 app.py

# API 테스트
curl -X GET "http://localhost:5000/api/crypto-data/db/date-with-previous?date=20250101"
curl -X GET "http://localhost:5000/api/macro-data/db/date-with-previous?date=20250101"
```

#### 3.2.3 iOS 앱 로컬 테스트
```bash
cd prospero_app

# Xcode에서 테스트 실행
xcodebuild test -project Prospero.xcodeproj -scheme Prospero -destination 'platform=iOS Simulator,name=iPhone 15'

# 또는 UI 테스트
xcodebuild test -project Prospero.xcodeproj -scheme Prospero -testPlan UITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 4. Docker 기반 테스트 환경

### 4.1 Docker Compose 구성

```bash
# 루트 디렉터리에 docker-compose.yml 생성
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # Local DynamoDB
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    ports:
      - "8000:8000"
    environment:
      - AWS_ACCESS_KEY_ID=local
      - AWS_SECRET_ACCESS_KEY=local
    command: "-jar DynamoDBLocal.jar -sharedDb -inMemory"

  # prospero_backend API
  prospero-backend:
    build:
      context: ./prospero_backend
      dockerfile: Dockerfile.dev
    ports:
      - "5000:5000"
    environment:
      - AWS_DEFAULT_REGION=ap-northeast-2
      - DYNAMODB_ENDPOINT_URL=http://dynamodb-local:8000
      - AWS_ACCESS_KEY_ID=local
      - AWS_SECRET_ACCESS_KEY=local
    depends_on:
      - dynamodb-local
    volumes:
      - ./prospero_backend:/app

  # Test runner
  test-harness:
    build:
      context: ./tests
      dockerfile: Dockerfile.test
    environment:
      - API_ENDPOINT=http://prospero-backend:5000
      - DYNAMODB_ENDPOINT=http://dynamodb-local:8000
    depends_on:
      - prospero-backend
      - dynamodb-local
    volumes:
      - ./tests:/tests
      - ./prospero_collector:/collector
      - ./prospero_backend:/backend

networks:
  default:
    name: prospero-test-network
EOF

# Docker Compose 실행
docker-compose up -d
```

### 4.2 Docker 기반 테스트 실행

```bash
# 컨테이너 내에서 통합 테스트 실행
docker-compose exec test-harness python -m pytest tests/ -v

# 특정 테스트만 실행
docker-compose exec test-harness python -m pytest tests/test_integration.py::test_crypto_data_flow -v

# 테스트 종료 및 정리
docker-compose down -v
```

---

## 5. AWS 통합 테스트 환경

### 5.1 스테이징 환경 설정

#### 5.1.1 Lambda 함수 배포 (스테이징)

```bash
# prospero_collector 스테이징 배포
cd prospero_collector
export FUNCTION_NAME=prospero-collector-staging
./deploy.sh $FUNCTION_NAME

# prospero_backend 스테이징 배포
cd prospero_backend
export FUNCTION_NAME=prospero-retrieval-staging
./deploy.sh $FUNCTION_NAME
```

#### 5.1.2 API Gateway 설정 (스테이징)

```bash
# AWS CLI를 사용하여 스테이징 API Gateway 생성
aws apigateway create-rest-api \
  --name prospero-retrieval-staging \
  --description "Prospero staging API" \
  --region ap-northeast-2
```

### 5.2 스테이징 테스트 케이스

```python
# tests/test_staging_integration.py
import boto3
import requests
import pytest
from datetime import datetime, timedelta

STAGING_API_ENDPOINT = "https://staging-api.prospero.example.com"
DYNAMODB_REGION = "ap-northeast-2"

class TestStagingIntegration:
    """스테이징 환경에서의 통합 테스트"""
    
    @pytest.fixture
    def dynamodb_table(self):
        dynamodb = boto3.resource('dynamodb', region_name=DYNAMODB_REGION)
        return dynamodb.Table('TB_CRYPTO_DATA')
    
    def test_crypto_data_collection_and_retrieval(self, dynamodb_table):
        """암호화폐 데이터 수집 및 조회 전체 flow 테스트"""
        # 1. 데이터 수집 (Lambda 호출)
        lambda_client = boto3.client('lambda', region_name=DYNAMODB_REGION)
        response = lambda_client.invoke(
            FunctionName='prospero-collector-staging',
            InvocationType='RequestResponse',
            Payload='{"date": "20250114"}'
        )
        assert response['StatusCode'] == 200
        
        # 2. DynamoDB에 데이터 저장 확인
        item = dynamodb_table.get_item(
            Key={'crypto_id': 'BTC', 'date': '20250114'}
        )
        assert 'Item' in item
        assert 'price' in item['Item']
        
        # 3. API를 통해 데이터 조회
        api_response = requests.get(
            f"{STAGING_API_ENDPOINT}/api/crypto-data/db/date-with-previous",
            params={'date': '20250114'}
        )
        assert api_response.status_code == 200
        data = api_response.json()
        assert 'current' in data
        assert 'previous' in data
    
    def test_macro_data_collection_and_retrieval(self, dynamodb_table):
        """거시경제 데이터 수집 및 조회 전체 flow 테스트"""
        # 1. 데이터 수집
        lambda_client = boto3.client('lambda', region_name=DYNAMODB_REGION)
        response = lambda_client.invoke(
            FunctionName='prospero-collector-staging',
            InvocationType='RequestResponse',
            Payload='{"date": "20250114"}'
        )
        assert response['StatusCode'] == 200
        
        # 2. API 조회
        api_response = requests.get(
            f"{STAGING_API_ENDPOINT}/api/macro-data/db/date-with-previous",
            params={'date': '20250114'}
        )
        assert api_response.status_code == 200
    
    def test_api_response_format(self):
        """API 응답 형식 검증"""
        response = requests.get(
            f"{STAGING_API_ENDPOINT}/api/crypto-data/db/date-with-previous",
            params={'date': '20250114'}
        )
        data = response.json()
        
        # 필수 필드 검증
        assert 'current' in data
        assert 'previous' in data
        assert isinstance(data['current'], dict)
        assert isinstance(data['previous'], dict)
```

---

## 6. E2E 테스트 (앱 + 백엔드)

### 6.1 E2E 테스트 구조

```python
# tests/test_e2e.py
import unittest
from unittest.mock import patch, MagicMock
import sys
import json

class TestAppEndToEnd(unittest.TestCase):
    """iOS 앱과 백엔드의 엔드-투-엔드 테스트"""
    
    def setUp(self):
        """테스트 환경 초기화"""
        self.api_endpoint = "http://localhost:5000"
        self.test_date = "20250114"
    
    def test_crypto_dashboard_data_flow(self):
        """암호화폐 대시보드 데이터 흐름 전체 테스트
        
        시나리오:
        1. 앱이 현재 날짜의 암호화폐 데이터 요청
        2. 백엔드가 DynamoDB에서 조회
        3. 앱이 데이터 수신 및 화면 표시
        """
        # 1. 데이터 준비
        test_data = {
            'crypto_id': 'BTC',
            'date': self.test_date,
            'price': 45000.00,
            'change_percent': 2.5,
            'market_cap': 890000000000
        }
        
        # 2. API 호출
        import requests
        response = requests.get(
            f"{self.api_endpoint}/api/crypto-data/db/date-with-previous",
            params={'date': self.test_date}
        )
        
        # 3. 응답 검증
        assert response.status_code == 200
        data = response.json()
        assert 'current' in data
        assert data['current']['crypto_id'] == 'BTC'
        
        # 4. 앱에서 표시할 데이터 형식 검증
        self._validate_app_display_format(data['current'])
    
    def test_macro_dashboard_data_flow(self):
        """거시경제 대시보드 데이터 흐름 전체 테스트"""
        import requests
        response = requests.get(
            f"{self.api_endpoint}/api/macro-data/db/date-with-previous",
            params={'date': self.test_date}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert 'current' in data
        
        # 앱 표시 형식 검증
        self._validate_macro_display_format(data['current'])
    
    def _validate_app_display_format(self, crypto_data):
        """앱에서 표시 가능한 데이터 형식 검증"""
        required_fields = ['crypto_id', 'date', 'price', 'change_percent']
        for field in required_fields:
            assert field in crypto_data, f"Missing required field: {field}"
    
    def _validate_macro_display_format(self, macro_data):
        """거시경제 데이터 표시 형식 검증"""
        required_fields = ['indicator_id', 'date', 'value']
        for field in required_fields:
            assert field in macro_data, f"Missing required field: {field}"

if __name__ == '__main__':
    unittest.main()
```

### 6.2 시간대 검증 E2E 테스트

```python
# tests/test_timezone_e2e.py
from datetime import datetime, timedelta
import pytz

class TestTimezoneBehavior(unittest.TestCase):
    """앱의 시간대 기반 데이터 요청 검증"""
    
    def test_usd_timezone_data_request(self):
        """USD 시간대 기준 데이터 요청 검증
        
        규칙:
        - 데이터 생성: UTC 04:00 (매일)
        - 앱 요청 기준: USD 시간 (America/New_York)
        - USD 시간이 04:00 미만이면 전날 데이터 요청
        """
        usd_tz = pytz.timezone('America/New_York')
        korea_tz = pytz.timezone('Asia/Seoul')
        
        # 시나리오: 한국 3월 3일 10:00 (USD 3월 2일 20:00)
        korea_time = korea_tz.localize(datetime(2025, 3, 3, 10, 0, 0))
        usd_time = korea_time.astimezone(usd_tz)
        
        # USD 시간이 04:00 미만인지 확인
        if usd_time.hour < 4:
            expected_date = (usd_time - timedelta(days=1)).strftime('%Y%m%d')
        else:
            expected_date = usd_time.strftime('%Y%m%d')
        
        # API 호출
        import requests
        response = requests.get(
            f"{self.api_endpoint}/api/crypto-data/db/date-with-previous",
            params={'date': expected_date}
        )
        
        assert response.status_code == 200

if __name__ == '__main__':
    unittest.main()
```

---

## 7. CI/CD 파이프라인 통합

### 7.1 GitHub Actions 워크플로우

```yaml
# .github/workflows/harness-test.yml
name: Harness Integration Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        component: [collector, backend]
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          cd prospero_${{ matrix.component }}
          pip install -r requirements.txt
          pip install pytest pytest-cov
      
      - name: Run unit tests
        run: |
          cd prospero_${{ matrix.component }}
          pytest tests/unit/ -v --cov

  integration-tests:
    needs: unit-tests
    runs-on: ubuntu-latest
    services:
      dynamodb:
        image: amazon/dynamodb-local:latest
        ports:
          - 8000:8000
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Install dependencies
        run: |
          pip install -r tests/requirements.txt
          pip install boto3 requests pytest
      
      - name: Run integration tests
        env:
          DYNAMODB_ENDPOINT_URL: http://localhost:8000
          AWS_DEFAULT_REGION: ap-northeast-2
        run: |
          pytest tests/test_integration.py -v

  e2e-tests:
    needs: integration-tests
    runs-on: ubuntu-latest
    services:
      dynamodb:
        image: amazon/dynamodb-local:latest
        ports:
          - 8000:8000
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Build and run backend
        run: |
          cd prospero_backend
          pip install -r requirements.txt
          python app.py &
      
      - name: Run E2E tests
        run: |
          pip install pytest requests
          pytest tests/test_e2e.py -v
      
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: test-results/
```

### 7.2 배포 후 검증 워크플로우

```yaml
# .github/workflows/post-deploy-verification.yml
name: Post-Deploy Verification

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Deploy environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

jobs:
  verify-deployment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ap-northeast-2
      
      - name: Run deployment verification tests
        env:
          ENVIRONMENT: ${{ github.event.inputs.environment }}
        run: |
          pip install pytest boto3 requests
          pytest tests/test_staging_integration.py -v
      
      - name: Send notification
        if: failure()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Post-deploy verification failed for ${{ github.event.inputs.environment }}'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 8. 테스트 케이스 체크리스트

### 8.1 단위 테스트 체크리스트

- [ ] prospero_collector
  - [ ] Binance API 데이터 파싱
  - [ ] Alternative.me Fear & Greed 지수 파싱
  - [ ] FRED API 데이터 파싱
  - [ ] DynamoDB 쓰기 로직
  - [ ] 에러 처리 및 재시도 로직

- [ ] prospero_backend
  - [ ] DynamoDB 쿼리 로직
  - [ ] API 응답 포맷팅
  - [ ] 날짜 파라미터 검증
  - [ ] 에러 응답 처리

- [ ] iOS App
  - [ ] ViewModel 로직
  - [ ] API Service 호출
  - [ ] 데이터 캐싱
  - [ ] 시간대 변환

### 8.2 통합 테스트 체크리스트

- [ ] 데이터 수집 → DynamoDB 저장 검증
- [ ] DynamoDB → API 조회 검증
- [ ] API → 앱 UI 표시 검증
- [ ] 날짜 전환 시 올바른 데이터 조회 검증
- [ ] 시간대 기반 데이터 요청 검증
- [ ] 에러 상황 처리 (API 오류, 네트워크 오류)

### 8.3 E2E 테스트 체크리스트

- [ ] 암호화폐 대시보드 전체 flow
- [ ] 거시경제 대시보드 전체 flow
- [ ] 데이터 새로고침
- [ ] 탭 전환
- [ ] 오프라인 모드 처리
- [ ] 데이터 업데이트 시간 표시

---

## 9. 테스트 데이터 관리

### 9.1 테스트 데이터 준비

```python
# tests/fixtures/test_data.py
import boto3
from datetime import datetime, timedelta

class TestDataManager:
    """테스트용 데이터 생성 및 관리"""
    
    def __init__(self, dynamodb_endpoint=None):
        self.dynamodb = boto3.resource(
            'dynamodb',
            endpoint_url=dynamodb_endpoint,
            region_name='ap-northeast-2'
        )
    
    def create_crypto_test_data(self, crypto_id='BTC', date='20250114'):
        """테스트용 암호화폐 데이터 생성"""
        table = self.dynamodb.Table('TB_CRYPTO_DATA')
        table.put_item(Item={
            'crypto_id': crypto_id,
            'date': date,
            'price': 45000.00,
            'change_percent': 2.5,
            'market_cap': 890000000000,
            'volume_24h': 35000000000,
            'timestamp': datetime.now().isoformat()
        })
    
    def create_macro_test_data(self, indicator_id='SPX', date='20250114'):
        """테스트용 거시경제 데이터 생성"""
        table = self.dynamodb.Table('TB_MACRO_DATA')
        table.put_item(Item={
            'indicator_id': indicator_id,
            'date': date,
            'value': 5500.50,
            'timestamp': datetime.now().isoformat()
        })
    
    def cleanup(self):
        """테스트 데이터 정리"""
        crypto_table = self.dynamodb.Table('TB_CRYPTO_DATA')
        macro_table = self.dynamodb.Table('TB_MACRO_DATA')
        
        # 테스트 데이터 삭제 (스캔 및 삭제)
        for table in [crypto_table, macro_table]:
            response = table.scan()
            with table.batch_writer() as batch:
                for item in response['Items']:
                    batch.delete_item(Key={k: item[k] for k in table.key_schema})
```

### 9.2 테스트 데이터 픽스처

```python
# tests/conftest.py
import pytest
from tests.fixtures.test_data import TestDataManager

@pytest.fixture(scope='session')
def dynamodb_endpoint():
    """DynamoDB Local 엔드포인트"""
    return "http://localhost:8000"

@pytest.fixture
def test_data_manager(dynamodb_endpoint):
    """테스트 데이터 매니저"""
    manager = TestDataManager(dynamodb_endpoint)
    yield manager
    manager.cleanup()

@pytest.fixture
def sample_crypto_data(test_data_manager):
    """샘플 암호화폐 데이터"""
    test_data_manager.create_crypto_test_data()
    return {'crypto_id': 'BTC', 'date': '20250114'}

@pytest.fixture
def sample_macro_data(test_data_manager):
    """샘플 거시경제 데이터"""
    test_data_manager.create_macro_test_data()
    return {'indicator_id': 'SPX', 'date': '20250114'}
```

---

## 10. 모니터링 및 보고

### 10.1 테스트 결과 리포팅

```python
# tests/test_reporter.py
import json
from datetime import datetime
from pathlib import Path

class TestReporter:
    """테스트 결과 리포팅"""
    
    def __init__(self, output_dir='test-results'):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
    
    def generate_report(self, test_results):
        """테스트 결과 리포트 생성"""
        report = {
            'timestamp': datetime.now().isoformat(),
            'summary': {
                'total': len(test_results),
                'passed': sum(1 for t in test_results if t['status'] == 'passed'),
                'failed': sum(1 for t in test_results if t['status'] == 'failed'),
                'skipped': sum(1 for t in test_results if t['status'] == 'skipped')
            },
            'tests': test_results
        }
        
        # JSON 리포트
        report_file = self.output_dir / f"test-report-{datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        # HTML 리포트 생성 (선택)
        self._generate_html_report(report, report_file.with_suffix('.html'))
        
        return report_file
    
    def _generate_html_report(self, report, output_file):
        """HTML 형식의 테스트 리포트 생성"""
        html_content = f"""
        <html>
            <head>
                <title>Prospero Harness Test Report</title>
                <style>
                    body {{ font-family: Arial, sans-serif; margin: 20px; }}
                    .summary {{ background: #f0f0f0; padding: 10px; margin: 10px 0; }}
                    .passed {{ color: green; }}
                    .failed {{ color: red; }}
                    table {{ border-collapse: collapse; width: 100%; }}
                    th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                </style>
            </head>
            <body>
                <h1>Prospero Harness Test Report</h1>
                <p>Generated: {report['timestamp']}</p>
                <div class="summary">
                    <h2>Summary</h2>
                    <p>Total: {report['summary']['total']}</p>
                    <p class="passed">Passed: {report['summary']['passed']}</p>
                    <p class="failed">Failed: {report['summary']['failed']}</p>
                    <p>Skipped: {report['summary']['skipped']}</p>
                </div>
                <table>
                    <tr><th>Test Name</th><th>Status</th><th>Duration</th></tr>
        """
        
        for test in report['tests']:
            status_class = 'passed' if test['status'] == 'passed' else 'failed'
            html_content += f"""
                    <tr>
                        <td>{test['name']}</td>
                        <td class="{status_class}">{test['status']}</td>
                        <td>{test.get('duration', 'N/A')}s</td>
                    </tr>
            """
        
        html_content += """
                </table>
            </body>
        </html>
        """
        
        with open(output_file, 'w') as f:
            f.write(html_content)

```

### 10.2 성능 모니터링

```python
# tests/performance_monitor.py
import time
from functools import wraps

def performance_monitor(func):
    """함수 실행 시간 모니터링 데코레이터"""
    @wraps(func)
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        elapsed_time = time.time() - start_time
        
        print(f"Function: {func.__name__}")
        print(f"Execution Time: {elapsed_time:.2f}s")
        
        if elapsed_time > 5:
            print(f"⚠️  Warning: Execution time exceeded 5 seconds")
        
        return result
    
    return wrapper

# 사용 예
class TestPerformance:
    @performance_monitor
    def test_api_response_time(self):
        """API 응답 시간 검증"""
        import requests
        
        start = time.time()
        response = requests.get(
            "http://localhost:5000/api/crypto-data/db/date-with-previous",
            params={'date': '20250114'}
        )
        elapsed = time.time() - start
        
        assert response.status_code == 200
        assert elapsed < 1, f"API response took {elapsed:.2f}s (expected < 1s)"
```

---

## 11. 문제 해결 가이드

### 11.1 일반적인 문제

| 문제 | 원인 | 해결 방법 |
|------|------|----------|
| DynamoDB Local 연결 실패 | 포트 8000 이미 사용 중 | `lsof -i :8000`으로 프로세스 확인 후 종료 |
| API 응답 404 | 라우팅 설정 오류 | API Gateway 설정 확인 및 함수명 검증 |
| 시간대 오류 | UTC와 로컬 시간 혼동 | 시간대 변환 로직 재확인 (CryptoAPIService.swift 참조) |
| DynamoDB 쿼리 느림 | 인덱스 미설정 | GSI 또는 LSI 설정 확인 |

### 11.2 로그 수집 및 분석

```bash
# Lambda 로그 조회
aws logs tail /aws/lambda/prospero-collector-staging --follow

# API Gateway 로그
aws logs tail /aws/api-gateway/prospero-retrieval-staging --follow

# 로컬 디버깅
export DEBUG=1
python3 prospero_backend/app.py
```

---

## 12. 체크리스트: Harness 엔지니어링 완료

### Phase 1: 로컬 개발 환경
- [ ] DynamoDB Local 설정
- [ ] 세 컴포넌트 로컬 실행 확인
- [ ] 기본 API 호출 테스트

### Phase 2: 단위 테스트
- [ ] prospero_collector 단위 테스트 작성
- [ ] prospero_backend 단위 테스트 작성
- [ ] iOS App 단위 테스트 작성
- [ ] 90% 이상 코드 커버리지 달성

### Phase 3: 통합 테스트
- [ ] Docker Compose 환경 구성
- [ ] 통합 테스트 시작 (수집 → 저장 → 조회)
- [ ] E2E 테스트 작성 (앱 + 백엔드)

### Phase 4: CI/CD 파이프라인
- [ ] GitHub Actions 워크플로우 구성
- [ ] 자동화된 테스트 실행
- [ ] 배포 후 검증 자동화

### Phase 5: 스테이징 검증
- [ ] 스테이징 환경에 배포
- [ ] 실제 AWS 환경에서 통합 테스트 실행
- [ ] 성능 모니터링

### Phase 6: 프로덕션 배포
- [ ] 모든 테스트 통과 확인
- [ ] 배포 전 최종 체크
- [ ] 배포 후 모니터링

---

## 13. 참고 문서

- [prospero_collector 배포 가이드](prospero_collector/LAMBDA_DEPLOYMENT.md)
- [prospero_backend 배포 가이드](prospero_backend/DEPLOYMENT.md)
- [iOS 앱 개발 가이드](prospero_app/README.md)
- [API 엔드포인트 설정](prospero_app/endpoint.md)

---

**마지막 업데이트**: 2026-05-14
**담당자**: Prospero 개발팀
