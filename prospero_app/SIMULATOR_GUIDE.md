# iOS 시뮬레이터 실행 가이드

앱을 가상의 아이폰(iOS 시뮬레이터)에서 실행하는 방법입니다.

## 방법 1: Xcode에서 직접 실행 (가장 쉬운 방법)

### 1단계: 프로젝트 열기
```bash
cd /Users/a78142/engn001/git/Prospero
open Prospero.xcodeproj
```

또는 Finder에서 `Prospero.xcodeproj` 파일을 더블클릭합니다.

### 2단계: 시뮬레이터 선택
1. Xcode 상단 툴바에서 **디바이스 선택 메뉴**를 클릭합니다
   - 기본적으로 "Any iOS Device" 또는 현재 선택된 디바이스가 표시됩니다
2. 원하는 iPhone 모델을 선택합니다:
   - **iPhone 15 Pro** (권장)
   - **iPhone 15**
   - **iPhone 14 Pro**
   - **iPhone SE** 등

### 3단계: 앱 실행
1. **⌘ + R** (Command + R) 키를 누르거나
2. 상단 툴바의 **▶️ (Play) 버튼**을 클릭합니다

### 4단계: 시뮬레이터 확인
- 시뮬레이터 창이 자동으로 열립니다
- 앱이 빌드되고 설치되면 자동으로 실행됩니다
- 시뮬레이터에서 앱을 직접 조작할 수 있습니다

## 방법 2: 터미널에서 시뮬레이터 실행

### 1단계: 시뮬레이터 목록 확인
```bash
xcrun simctl list devices
```

### 2단계: 특정 시뮬레이터 부팅
```bash
xcrun simctl boot "iPhone 15 Pro"
```

### 3단계: 시뮬레이터 앱 열기
```bash
open -a Simulator
```

### 4단계: Xcode에서 빌드 및 실행
- Xcode에서 ⌘ + R로 실행하면 부팅된 시뮬레이터에 설치됩니다

## 시뮬레이터 사용 팁

### 기본 제스처
- **터치**: 마우스 클릭
- **스와이프**: 마우스 드래그
- **핀치 줌**: Option 키를 누른 채 드래그
- **롱 프레스**: 마우스 클릭 후 길게 누르기

### 유용한 단축키
- **⌘ + ←/→**: 홈 화면으로 돌아가기
- **⌘ + Shift + H**: 홈 화면
- **⌘ + K**: 키보드 표시/숨기기
- **⌘ + S**: 스크린샷 저장
- **⌘ + Shift + K**: 빌드 클린

### 시뮬레이터 설정
1. **Settings** 앱 열기
2. **General > About**에서 시뮬레이터 정보 확인
3. **Developer** 메뉴에서 추가 옵션 설정

## 문제 해결

### 시뮬레이터가 열리지 않을 때
```bash
# 모든 시뮬레이터 프로세스 종료
killall Simulator

# 다시 시뮬레이터 열기
open -a Simulator
```

### 빌드 에러가 발생할 때
1. **⌘ + Shift + K**: Clean Build Folder
2. **⌘ + B**: 다시 빌드
3. Xcode 재시작

### 앱이 실행되지 않을 때
1. 시뮬레이터 재부팅
2. 앱 삭제 후 재설치
3. 시뮬레이터 초기화 (Settings > General > Reset)

## 다양한 디바이스 테스트

### iPhone 모델 변경
1. Xcode 상단에서 디바이스 선택
2. 원하는 iPhone 모델 선택
3. 다시 실행 (⌘ + R)

### iPad 테스트
1. 디바이스 선택 메뉴에서 iPad 모델 선택
2. 실행하여 iPad 레이아웃 확인

## 네트워크 테스트

### localhost 연결
- 시뮬레이터에서 `localhost:8080`은 호스트 머신의 `localhost:8080`을 가리킵니다
- 백엔드 서버가 실행 중이면 정상적으로 연결됩니다

### 네트워크 상태 시뮬레이션
1. 시뮬레이터 메뉴: **Device > Network Link Conditioner**
2. 다양한 네트워크 상태 테스트 가능

## 성능 모니터링

### 디버깅 도구
- **⌘ + Y**: 디버그 콘솔 열기/닫기
- **⌘ + Shift + Y**: 로그 확인
- **Instruments**: 성능 프로파일링 도구

## 스크린샷 및 비디오

### 스크린샷
- **⌘ + S**: 현재 화면 스크린샷 저장
- 저장 위치: Desktop

### 비디오 녹화
1. 시뮬레이터 메뉴: **Device > Record Screen**
2. 녹화 시작/중지
3. 저장 위치: Desktop

## 빠른 실행 스크립트

프로젝트 루트에 `run_simulator.sh` 파일을 만들고:

```bash
#!/bin/bash
cd "$(dirname "$0")"
open Prospero.xcodeproj
```

실행 권한 부여:
```bash
chmod +x run_simulator.sh
```

실행:
```bash
./run_simulator.sh
```


