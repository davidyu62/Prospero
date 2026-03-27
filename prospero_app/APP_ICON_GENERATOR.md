# 앱 아이콘 생성 가이드

현재 헤더에 있는 아이콘 디자인을 앱 메인 아이콘으로 사용하려면 다음 단계를 따르세요:

## 방법 1: Xcode Preview를 사용하여 이미지 생성

1. Xcode에서 `AppIconGenerator.swift` 파일을 엽니다
2. Preview를 실행합니다 (⌘ + Option + P)
3. Preview에서 아이콘을 우클릭하고 "Copy" 또는 스크린샷을 찍습니다
4. 1024x1024 크기로 리사이즈합니다
5. `Assets.xcassets/AppIcon.appiconset/` 폴더에 저장합니다

## 방법 2: SwiftUI View를 이미지로 렌더링하는 코드 사용

다음 코드를 사용하여 앱 아이콘 이미지를 생성할 수 있습니다:

```swift
import SwiftUI

func generateAppIcon() {
    let iconView = AppIconView(size: 1024)
    let renderer = ImageRenderer(content: iconView)
    
    if let uiImage = renderer.uiImage {
        // 이미지를 저장하거나 클립보드에 복사
        if let pngData = uiImage.pngData() {
            // 파일로 저장하거나 사용
        }
    }
}
```

## 방법 3: 수동으로 이미지 생성

1. 디자인 도구(Photoshop, Sketch, Figma 등)를 사용하여 다음 스펙으로 이미지를 만듭니다:
   - 크기: 1024x1024 픽셀
   - 형식: PNG (투명 배경 없음)
   - 디자인: AppIconView.swift의 디자인 참고

2. 생성한 이미지를 `Prospero/Prospero/Assets.xcassets/AppIcon.appiconset/AppIcon.png`로 저장합니다

3. `Contents.json` 파일을 업데이트합니다:
   ```json
   {
     "images" : [
       {
         "filename" : "AppIcon.png",
         "idiom" : "universal",
         "platform" : "ios",
         "size" : "1024x1024"
       }
     ],
     "info" : {
       "author" : "xcode",
       "version" : 1
     }
   }
   ```

## 현재 아이콘 디자인

현재 아이콘은 다음 특징을 가지고 있습니다:
- 블랙 계열 그라데이션 배경
- 미묘한 테두리 효과
- "sparkles" 아이콘 (반짝이는 효과)
- 그림자 효과로 입체감

이 디자인을 그대로 사용하거나, 필요에 따라 수정할 수 있습니다.


