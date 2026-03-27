# Prospero

iOS 앱 프로젝트

## iPhone에 빌드하고 테스트하는 방법

### 1. 사전 준비
- iPhone을 USB 케이블로 Mac에 연결
- iPhone에서 "이 컴퓨터를 신뢰" 선택 (처음 연결 시)
- Xcode가 설치되어 있어야 함

### 2. Xcode에서 프로젝트 열기
```bash
open Prospero.xcodeproj
```

또는 Xcode를 실행한 후 `File > Open`으로 프로젝트를 엽니다.

### 3. Signing & Capabilities 설정

1. **프로젝트 네비게이터**에서 최상위 "Prospero" 프로젝트를 선택
2. **TARGETS**에서 "Prospero" 선택
3. **Signing & Capabilities** 탭 클릭
4. **Automatically manage signing** 체크박스 선택
5. **Team** 드롭다운에서 Apple ID 선택
   - Apple ID가 없으면 "Add Account..." 클릭하여 추가
   - 무료 Apple ID로도 개발용 앱을 빌드할 수 있습니다

### 4. Bundle Identifier 설정 (필요시)

현재 Bundle Identifier: `com.davidyu.Prospero`

만약 이미 사용 중인 ID라면 변경:
- **Signing & Capabilities** 탭에서 **Bundle Identifier** 변경
- 예: `com.yourname.prospero`

### 5. 기기 선택 및 빌드

1. Xcode 상단 툴바에서 **기기 선택** 드롭다운 클릭
2. 연결된 iPhone 선택 (예: "Your iPhone's Name")
3. **⌘ + R** (또는 Play 버튼) 클릭하여 빌드 및 실행

### 6. iPhone에서 신뢰 설정 (첫 실행 시)

앱을 처음 실행할 때:
1. iPhone에서 "설정" 앱 열기
2. **일반 > VPN 및 기기 관리** (또는 **일반 > 기기 관리**)
3. 개발자 앱 섹션에서 Apple ID 선택
4. **신뢰** 버튼 탭
5. 다시 앱 실행

### 7. 명령줄에서 빌드 (선택사항)

```bash
# 프로젝트 디렉토리로 이동
cd /Users/a78142/engn001/git/Prospero

# 연결된 기기 목록 확인
xcrun xctrace list devices

# 빌드 (시뮬레이터용)
xcodebuild -project Prospero.xcodeproj -scheme Prospero -sdk iphonesimulator -configuration Debug

# 실제 기기에 빌드하려면 Xcode에서 Signing 설정이 필요합니다
```

## 문제 해결

### "No signing certificate found"
- Xcode에서 Apple ID로 로그인 확인
- Signing & Capabilities에서 Team 선택 확인

### "Device not found"
- iPhone이 연결되어 있는지 확인
- iPhone에서 "이 컴퓨터를 신뢰" 선택 확인
- Xcode > Window > Devices and Simulators에서 기기 확인

### "App installation failed"
- iPhone에서 개발자 앱 신뢰 설정 확인
- Bundle Identifier가 고유한지 확인

## 참고사항

- 무료 Apple ID로도 개발용 앱을 빌드할 수 있습니다 (7일마다 재서명 필요)
- 유료 Apple Developer Program ($99/년)에 가입하면 더 많은 기능 사용 가능
- 현재 프로젝트는 iOS 26.2 이상을 대상으로 합니다
