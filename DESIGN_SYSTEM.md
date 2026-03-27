# Prospero UI/UX 개선 설계서

## 1. 색상 시스템

### 프리미엄 다크 테마 (기본)
```
배경색:
- 주 배경: #0F1117 (깊은 검정)
- 카드 배경: #161B22 (약간 밝은 검정)
- 강조 배경: #1C2128 (가장 밝은 회색)

주요 색상:
- Primary: Linear Gradient (파란색 #00D9FF → 보라색 #7C3AED)
- Accent: #FFA500 (골드/오렌지)
- Success: #10B981 (녹색)
- Warning: #F59E0B (주황색)
- Danger: #EF4444 (빨강)

텍스트:
- Primary Text: #FFFFFF (흰색)
- Secondary Text: #A0AEC0 (밝은 회색)
- Tertiary Text: #718096 (중간 회색)
- Disabled Text: #4A5568 (어두운 회색)
```

### 라이트 테마
```
배경색:
- 주 배경: #F8FAFC (밝은 하늘색)
- 카드 배경: #FFFFFF (흰색)
- 강조 배경: #F1F5F9 (밝은 회색)

주요 색상:
- Primary: Linear Gradient (파란색 #0EA5E9 → 보라색 #8B5CF6)
- Accent: #F97316 (주황색)
- 나머지는 동일

텍스트:
- Primary Text: #0F172A (어두운 파란색)
- Secondary Text: #475569 (중간 회색)
- Tertiary Text: #94A3B8 (밝은 회색)
- Disabled Text: #CBD5E1 (매우 밝은 회색)
```

---

## 2. 타이포그래피

### 폰트 계층
```
- Display: SF Pro Display, 32px, Bold
- Heading 1: SF Pro Display, 24px, Bold
- Heading 2: SF Pro Display, 20px, Semibold
- Heading 3: SF Pro Display, 18px, Semibold
- Body Large: SF Pro Text, 16px, Regular
- Body: SF Pro Text, 14px, Regular
- Body Small: SF Pro Text, 12px, Regular
- Caption: SF Pro Text, 11px, Regular
```

### 라인 높이
```
- Display: 120%
- Heading: 130%
- Body: 150%
- Caption: 140%
```

---

## 3. 컴포넌트 개선

### 3.1 카드 (모든 탭)
```
변경 전:
- 단순 회색 배경
- 기본 코너 반지름

변경 후:
- 배경: 그라데이션 또는 투명도 있는 배경
- 코너 반지름: 16px
- 그림자: 0 4px 12px rgba(0,0,0,0.15) (다크), rgba(0,0,0,0.08) (라이트)
- Border: 1px, rgba(255,255,255,0.1) (다크) / rgba(0,0,0,0.05) (라이트)
- 호버 효과: 배경 밝기 10% 증가
```

### 3.2 버튼
```
Primary Button:
- 배경: Primary Gradient (#00D9FF → #7C3AED)
- 텍스트: 흰색
- 코너 반지름: 12px
- 높이: 48px
- 폰트: 16px, Semibold
- 그림자: 0 4px 12px Primary.opacity(0.4)

Secondary Button:
- 배경: Secondary Color.opacity(0.1)
- Border: 1px, Secondary Color
- 텍스트: Secondary Color
```

### 3.3 진행 바
```
배경: Linear Gradient (왼쪽 파란색 → 오른쪽 보라색)
높이: 6px
코너 반지름: 3px
애니메이션: 부드러운 애니메이션
```

### 3.4 원형 게이지 (AI 점수)
```
배경 스트로크: 2px, Secondary.opacity(0.2)
진행 스트로크: 12px, Primary Gradient
선 끝: Round
애니메이션: 2초 easeInOut
```

---

## 4. 화면별 개선

### 4.1 Crypto Dashboard
```
Header:
- 앱 이름 + 새로고침 버튼
- 마지막 업데이트 시간 표시
- 배경: 서브틀한 그라데이션

Bitcoin Card:
┌─────────────────────────────────┐
│ ₿ Bitcoin                   🔄  │
├─────────────────────────────────┤
│ $43,250.50                      │
│ ▲ 2.50%                         │
│                                 │
│ [7일 차트 공간 예약]            │
└─────────────────────────────────┘

지표 카드:
- Fear & Greed: 원형 게이지
- Long/Short: 진행 바
- 각 카드: 아이콘 + 값 + 선택 가능한 상세
```

### 4.2 Macro Dashboard
```
유사한 레이아웃으로 개선
- 각 지표: 아이콘 + 제목 + 값
- 호버 시: 배경색 변화
- 탭 네비게이션: 아래쪽 정렬
```

### 4.3 AI Analysis View
```
메인 점수 섹션:
┌──────────────────────────────────┐
│         ◯ 56 / 100              │
│       Strong Buy                 │
│                                  │
│ 현재 시장은 매수 신호를 보이고   │
│ 있습니다...                      │
└──────────────────────────────────┘

점수 분류:
┌─────────────┬─────────────┐
│ Crypto      │ Macro       │
│ 45 / 60     │ 11 / 40     │
└─────────────┴─────────────┘

지표 분석:
- 제목: "암호화폐 지표"
- 각 지표: 라벨 + 진행 바 + 점수
- 배경: 서브틀한 색상

상세 설명:
- 접기/펼치기 가능
- 부드러운 애니메이션
```

---

## 5. 간격 및 여백 시스템

```
4px: 매우 작은 간격 (아이콘 사이)
8px: 작은 간격 (요소 사이)
12px: 중간 간격
16px: 기본 간격 (카드 내부)
20px: 큰 간격
24px: 섹션 사이
32px: 화면 상단/하단
```

---

## 6. 애니메이션

### 지속 시간
```
빠른: 150ms (호버, 상태 변화)
표준: 300ms (화면 전환)
느린: 500ms (로딩 애니메이션)
```

### 이징
```
- 기본: easeInOut
- 진입: easeOut
- 퇴출: easeIn
```

---

## 7. 어두운 모드 최적화

### 명도 대비
```
배경: #0F1117 (0% 밝기)
카드: #161B22 (9% 밝기)
강조: #1C2128 (11% 밝기)
텍스트: #FFFFFF (100% 밝기)

WCAG AA 준수: 모든 텍스트가 4.5:1 이상 대비
```

---

## 8. 아이콘 가이드

```
크기:
- 작음: 16px
- 중간: 20px
- 큼: 24px
- 특대: 40px+

색상:
- Primary: Primary Color
- Secondary: Secondary Text
- Disabled: Disabled Text

스타일: SF Symbols (Apple)
```

---

## 9. 상태 표현

### 로딩
```
- ProgressView: Primary Gradient
- 텍스트: "데이터 로딩 중..."
- 배경: 반투명
```

### 에러
```
- 아이콘: 빨간 느낌 (⚠️)
- 텍스트: Danger Color
- 배경: Danger.opacity(0.1)
```

### 성공
```
- 아이콘: 초록색 느낌 (✓)
- 텍스트: Success Color
- 배경: Success.opacity(0.1)
```

---

## 10. 구현 우선순위

### Phase 1 (즉시)
- [ ] 색상 시스템 업데이트
- [ ] 카드 그림자 및 보더 추가
- [ ] 타이포그래피 개선

### Phase 2 (1주)
- [ ] 그라데이션 배경 추가
- [ ] 컴포넌트 애니메이션
- [ ] 호버 효과 구현

### Phase 3 (2주)
- [ ] 고급 애니메이션
- [ ] 마이크로인터랙션
- [ ] 접근성 개선

---

## 색상 코드 참조

### 다크 테마
```swift
let darkBackground = Color(red: 15/255, green: 17/255, blue: 23/255)
let darkCard = Color(red: 22/255, green: 27/255, blue: 34/255)
let darkAccent = Color(red: 28/255, green: 33/255, blue: 40/255)
let primaryGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0, green: 217/255, blue: 255/255),
        Color(red: 124/255, green: 58/255, blue: 237/255)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### 라이트 테마
```swift
let lightBackground = Color(red: 248/255, green: 250/255, blue: 252/255)
let lightCard = Color.white
let lightAccent = Color(red: 241/255, green: 245/255, blue: 249/255)
let primaryGradient = LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 14/255, green: 165/255, blue: 233/255),
        Color(red: 139/255, green: 92/255, blue: 246/255)
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

이 설계를 기반으로 코드를 업데이트하시겠습니까?
