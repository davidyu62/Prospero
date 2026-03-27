#!/usr/bin/env swift

// 앱 아이콘 생성 스크립트
// 사용법: swift generate_app_icon.swift

import SwiftUI
import AppKit

struct AppIconView: View {
    var size: CGFloat = 1024
    
    var body: some View {
        ZStack {
            // Background - Dark gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.12),
                            Color(red: 0.05, green: 0.05, blue: 0.07)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: size * 0.01
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: size * 0.02, x: 0, y: size * 0.01)
            
            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: size * 0.4, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: size, height: size)
    }
}

// Note: 이 스크립트는 macOS에서만 실행 가능합니다.
// 실제 앱 아이콘 이미지를 생성하려면 Xcode Preview를 사용하거나
// 디자인 도구를 사용하여 1024x1024 PNG 이미지를 생성하세요.

print("앱 아이콘 생성 가이드:")
print("1. Xcode에서 AppIconGenerator.swift 파일을 엽니다")
print("2. Preview를 실행합니다 (⌘ + Option + P)")
print("3. Preview에서 아이콘을 우클릭하여 이미지로 저장하거나")
print("4. 스크린샷을 찍어서 1024x1024 크기로 리사이즈합니다")
print("5. Assets.xcassets/AppIcon.appiconset/ 폴더에 AppIcon.png로 저장합니다")


